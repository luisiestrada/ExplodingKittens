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

    new_index = self.current_turn_player_index + 1
    new_index = 0 if new_index > self.players.length - 1

    self.current_turn_player_index = new_index
    self.save!
  end

  def end!
    self.players.map(&:leave_game!)
    self.active = false
    self.save!
  end

  def deck
    self.draw_pile_ids
    .map { |id| PlayingCard.find(id) }
    .select { |card| card.state == 'deck'}
  end

  def draw(n=1)
    self.deck.first(n)
  end

  def shuffle_deck!
    self.draw_pile_ids = self.playing_cards.map(&:id).shuffle
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
    self.current_turn_player.id == player.id
  end

  def current_turn_player
    self.players
      .where(id: self.turn_orders[self.current_turn_player_index])
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
