class Game < ActiveRecord::Base
  belongs_to :winner, class_name: User
  has_many :users
  has_many :stats, class_name: GameStat
  has_many :playing_cards
  has_one :host, class_name: User

  after_save :set_room_name

  alias :players :users
  serialize :draw_pile_ids, Array
  serialize :turn_orders, Hash

  MIN_PLAYERS = 2
  MAX_PLAYERS = 5
  VALID_CARD_TYPES = Set[
    'attack', 'pair', 'favor', 'nope', 'defuse', 'exploding_kitten',
    'see_the_future', 'shuffle', 'skip'
  ]

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_winner, -> (user) { where(winner_id: user.id) }
  scope :with_players, -> {
    joins(:users)
    .group('games.id')
    .having('count(users.id) > 0')
  }

  def start_game!
    # init the deck
    (VALID_CARD_TYPES - ['exploding_kitten', 'defuse']).each do |card_type|
      init_card_by_type(card_type)
    end

    # game setup: https://www.explodingkittens.com/explodingkittensrules.pdf
    # Rules say that there should be 1 less bomb than the player count
    init_card_by_type('exploding_kitten', qty: self.players.count - 1)
    init_card_by_type('defuse')

    self.shuffle_deck!

    # pass out 1 defuse card & 4 other cards to each player

    self.players.each do |player|
      player.hand << self.playing_cards
        .where(state: 'deck')
        .where(card_type: 'defuse')
        .first

      4.times do
        player.hand << self.deck
          .reject { |card| ['defuse', 'exploding_kitten'].include?(card.card_type) }
          .first
      end

      player.save!
    end

    # pick a random player to go first,
    # setup the hash that keeps track of turn order
    player_id = self.players.sample.id
    self.turn_orders = { 0 => player_id }
    self.current_turn_player_index = 0

    self.players
      .where.not(id: player_id)
      .each_with_index { |player, i| self.turn_orders[i + 1] = player.id }

    self.active = true
    self.save!
  end

  def add_user(user)
    return false unless self.users.count < MAX_PLAYERS

    user.leave_game! if user.game_id.present?
    self.host_id = user.id if self.host_id.nil?
    user.is_playing = true
    self.users << user
    user.save!
    self.save!
  end

  def remove_user(user)
    self.reset_turn_orders!(user)
    user.leave_game!
  end

  def active_players
    self.players.where(is_playing: true)
  end

  def end_current_turn!
    current_player = self.current_turn_player

    if current_player.has_drawn?
      current_player.has_drawn = false
      current_player.save!
    end

    if current_player.turns_to_take > 1
      current_player.turns_to_take -= 1
      current_player.save!
      return
    end

    new_index = self.current_turn_player_index + 1
    new_index = 0 if new_index > self.players.length - 1

    self.current_turn_player_index = new_index
    self.save!
  end

  def win_player!(player)
    self.winner_id = player.id
    self.save!
  end

  def lose_player!(player)
    self.reset_turn_orders!(player)
    player.lose!
  end

  def end!
    self.players.map(&:leave_game!)
    self.active = false
    self.save!
  end

  def deck
    self.draw_pile_ids
    .map { |id| PlayingCard.find(id) }
    .select { |card| card.state == 'deck' }
  end

  def draw(n=1)
    self.deck.first(n)
  end

  def reset_turn_orders!(player_to_exclude)
    # find the index of the of the player to exclude in order to remove
    # them yet preserve the ordering

    old_ordering = self.turn_orders.dup

    index_to_exclude = nil
    self.turn_orders.each do |index, player_id|
      if player_to_exclude.id == player_id
        index_to_exclude = index
        break
      end
    end

    # edge case, if this was the last guy in the turn ordering we can
    # just pop him off
    if index_to_exclude == self.players.length - 1
      self.turn_orders.delete(index_to_exclude)
    else
      # move everyone back one step
      old_ordering.each do |index, player_id|
        if index > index_to_exclude
          self.turn_orders[index - 1] = player_id
        end
      end
    end

    self.save!
  end

  def play_card(actor, card, target_player: nil, target_card: nil)
    # Here begins the ugliest method I've ever written, quick & dirty.
    # I'm ashamed.

    global_announcements = []
    player_announcements = []
    action = { key: nil, data: {} }

    card_was_played = false
    can_play_card = (self.current_turn_player.is_playing? &&
      (self.current_turn_player.id == actor.id ||
      card.card_type == 'nope'))

    stats = actor.stats

    if can_play_card && actor.has_card?(card)
      case card.card_type
      when 'defuse'
        if actor.has_card?('exploding_kitten')
          global_announcements << "#{actor.username} saved themselves from"\
            " an exploding kitten with a defuse card!"
          card_was_played = true
        end
      when 'attack'
        # end your turn without drawing and force the next player
        # to take 2 turns in a row

        if actor.turns_to_take > 1
          # if the victim of an attack card plays an attack card,
          # then their turn is immeidately over and the next player
          # must take 2 turns
          actor.turns_to_take = 1
          actor.save!
        end

        next_player = self.next_turn_player
        next_player.turns_to_take = 2
        next_player.save!

        self.end_current_turn!
        card_was_played = true
      when 'skip'
        self.end_current_turn!
        card_was_played = true
      when 'shuffle'
        self.shuffle_deck!(true)
        card_was_played = true
      when 'see_the_future'
        action[:data][:drawn_cards] = self.draw(3)
        action[:key] = 'see_the_future'
        card_was_played = true
      when 'favor'
        # Two Phases:

        # 1. player plays card, we verify they can play it, then we tell that
        # player to choose a card from their hand to give up.

        if target_player && target_player.is_playing?
          if target_player.hand.length > 0
            # Target player hasn't chosen a card yet. Pass that event to the
            # player and wait for the response in the controller.

            action[:key] = 'favor'
            action[:data][:target_player] = target_player

            player_announcements << "Waiting for card from "\
              "#{target_player.username}..."
            card_was_played = true
          else
            player_announcements << " The player you targeted does not have "\
              "any cards in their hand. Choose another player."
          end
        else
          player_announcements << "The player you targeted does not exist "\
            " or is no longer playing."
        end
      when 'pair'
        if actor.hand.where(card_name: card.card_name).length >= 2
          if target_player && target_player.is_playing?
            if target_player.hand.length > 0
              stolen_card = target_player.hand.sample
              action[:data][:stolen_card] = stolen_card.as_json
              action[:key] = 'pair'

              actor.hand << stolen_card
              card_was_played = true

              stats.card_combos_played += 1
              stats.save!

            else
              player_announcements << " The player you targeted does not have "\
                "any cards in their hand. Choose another player."
            end
          else
            player_announcements << "The player you targeted does not exist "\
              " or is no longer playing."
          end
        else
          player_announcements << "You need another pair card of the same name"\
            " to player that. Pair cards must be played in pairs."
        end
      end
    end

    if card && card_was_played
      card.user_id = nil
      card.discarded = true
      card.save!

      stats.cards_played += 1
      stats.save!

      action[:data][:discarded_card_ids] = [card.id]

      if card.card_type == 'pair'
        card2 = actor.hand
          .where(card_name: card.card_name)
          .where.not(id: card.id)
          .first
        card2.user_id = nil
        card2.discarded = true
        card2.save!

        action[:data][:discarded_card_ids] << card2.id
      end

      message = " played #{card.card_name}"
      message << " on #{target_player.username}" if target_player
      message << "!"

      global_announcements << "#{actor.username}#{message}"
      player_announcements << "You #{message}"
    else
      player_announcements << "You can't play that." if player_announcements.empty?
    end

    {
      card_was_played: card_was_played,
      action: action,
      global_announcements: global_announcements.join("\n"),
      player_announcements: player_announcements.join("\n")
    }
  end

  def shuffle_deck!(ignore_discard=false)
    if ignore_discard
      self.draw_pile_ids = self.playing_cards
        .where(state: 'deck')
        .map(&:id).shuffle
    else
      self.draw_pile_ids = self.playing_cards.map(&:id).shuffle
    end

    self.save!
  end

  def discard_pile
    self.playing_cards.where(state: 'discarded')
  end

  def valid_player_count?
    self.players.count.between?(MIN_PLAYERS, MAX_PLAYERS)
  end

  def max_players_reached?
    self.users.count == MAX_PLAYERS
  end

  def channel_for_player(player)
    "#{player.id}#{self.created_at.to_i}#{self.id}"
  end

  def as_json
    data = {}

    data[:current_turn_id] = self.current_turn_player.id
    data[:players] = self.players.map do |player|
      {
        id: player.id,
        username: player.username
      }
    end

    data
  end

  def can_draw?(player)
    self.current_turn_player.id == player.id && self.current_turn_player.try(:is_playing?)
  end

  def current_turn_player
    self.players
      .where(id: self.turn_orders[self.current_turn_player_index])
      .first
  end

  def next_turn_player
    index = self.current_turn_player_index + 1
    index = 0 if index > self.players.length - 1

    self.players
      .where(id: self.turn_orders[index])
      .first
  end

  private

  def set_room_name
    if self.room_name.blank?
      self.room_name = "Game #{self.id}"
      self.save!
    end
  end

  def init_card_by_type(type, qty:nil)
    template = Settings.card_templates[type]
    raise "'#{type}' is not a valid card type." unless (template && VALID_CARD_TYPES.include?(type))

    Game.transaction do
      if type == 'pair'
        template.each do |pair_card|
          (qty || pair_card.default_quantity).times do
            self.playing_cards << PlayingCard.build_from_template(pair_card.to_h)
          end
        end
      else
        (qty || template.default_quantity).times do
          self.playing_cards << PlayingCard.build_from_template(template.to_h)
        end
      end

      self.save!
    end
  end
end
