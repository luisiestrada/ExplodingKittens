class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  belongs_to :game
  has_one :stats, class_name: UserStat
  has_many :games_won, foreign_key: :winner_id, class_name: Game
  has_many :playing_cards

  alias :hand :playing_cards

  validates_presence_of :email, :encrypted_password
  validates_numericality_of :wins, :losses,
    only_integer: true, greater_than_or_equal_to: 0
  validates_associated :playing_cards

  before_create :generate_anon_username
  after_create :init_stats

  def start_turn
    self.has_drawn = false
  end

  def draw(n=1)
    cards = self.game.draw(self, n)
    self.hand = self.hand + cards
    self.has_drawn = true
    self.save!
  end

  def is_game_host?
    self.id == self.game.host.id
  end

  def has_card?(card_type)
    self.hand.where(card_type: card_type).length > 0
  end

  def has_exploding_kitten?
    self.hand.where(card_type: 'exploding_kitten').length > 0
  end

  def has_defuse?
    self.hand.where(card_type: 'defuse').length > 0
  end

  def clear_hand!
    self.playing_cards.delete_all
  end

  def lose!
    self.losses += 1
    self.is_playing = false
    self.clear_hand!
    self.save!
  end

  def games_played
    self.wins + self.losses
  end

  def win_loss_ratio
    return 0.0 if self.games_played == 0
    return 100.0 if self.losses == 0
    self.wins / self.losses
  end

  private

  def generate_anon_username
    self.username = "Anon-#{self.object_id}"
  end

  def init_stats
    UserStat.create(user_id: self.id)
  end
end
