class Game < ActiveRecord::Base
  belongs_to :winner, class_name: User
  has_many :users
  has_many :stats, class_name: GameStat
  has_many :playing_cards

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
      self.init_card_by_type(card_type)
    end

    # game setup: https://www.explodingkittens.com/explodingkittensrules.pdf
    self.shuffle_deck!

    # Rules say that there should be 1 less bomb than the player count
    self.init_card_by_type('exploding_kitten', self.players.count - 1)
    self.init_card_by_type('defuse')

    # pass out 1 defuse card & 4 other cards to each player
    self.players.each do |player|
      player.hand << self.playing_cards
        .where(card_type: 'defuse')
        .where(state: 'deck')
        .first

      4.times do
        player.hand << self.playing_cards.where(
          "card_type != 'defuse' AND
           card_type != 'exploding_kitten' AND
           state = 'deck'"
        ).first
      end

      player.save!
    end

    self.active = true
    self.save!
  end

  def add_user(user)
    return false unless self.users.count < (MAX_PLAYERS - 1)

    self.users << user
    self.save!
  end

  def remove_user(user)
    self.users.delete(user)
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

  private

  def init_card_by_type(type, qty:nil)
    raise 'Invalid card type!' unless VALID_CARD_TYPES.include?(type)

    (qty || card.default_quantity).times do
      self.playing_cards << PlayingCard.create_from_template(Settings.playing_cards[type])
    end

    self.save!
  end
end
