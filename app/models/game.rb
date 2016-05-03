class Game < ActiveRecord::Base
  belongs_to :winner, class_name: User
  has_many :users
  has_many :stats, class_name: GameStat
  has_many :playing_cards
  has_one :current_turn_player, class_name: User

  alias :players :users

  MIN_PLAYERS = 2
  MAX_PLAYERS = 5
  VALID_CARD_TYPES = Set[
    'attack', 'pair', 'favor', 'nope', 'defuse', 'exploding_kitten',
    'see_the_future', 'shuffle', 'skip'
  ]

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_winner, -> (user) { where(winner_id: user.id) }

  def start_game
    # init the deck
    (VALID_CARD_TYPES - ['exploding_kitten', 'defuse']).each do |card_type|
      init_card_by_type(card_type)
    end

    # game setup: https://www.explodingkittens.com/explodingkittensrules.pdf
    self.shuffle_deck!

    # Rules say that there should be 1 less bomb than the player count
    init_card_by_type('exploding_kitten', qty: self.players.count - 1)
    init_card_by_type('defuse')

    # pass out 1 defuse card & 4 other cards to each player
    self.players.each do |player|
      player.hand << self.deck.where(card_type: 'defuse').first

      4.times do
        player.hand << self.deck
          .where.not(card_type: 'defuse')
          .where.not(card_type: 'exploding_kitten')
          .first
      end

      player.save!
    end

    # pick a random player to go first
    player_id = self.players.pluck(:id).sample
    self.set_turn(User.find(player_id))

    self.active = true
    self.save!
  end

  def add_user(user)
    return false unless self.users.count < MAX_PLAYERS
    self.users << user
    self.save!
  end

  def remove_user(user)
    self.users.delete(user)
  end

  def set_turn(player)
    self.current_turn_player = player
    self.save!
  end

  def end!
    self.users.delete_all
  end

  def deck
    self.playing_cards.where(state: 'deck')
  end

  def shuffle_deck!
    self.playing_cards.shuffle
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

  private

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
