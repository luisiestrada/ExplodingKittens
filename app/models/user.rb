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

  def is_game_host?
    self.id == self.game.host.id
  end

  def has_card?(card)
    case card
    when String
      self.hand.where(card_type: card).length > 0
    when PlayingCard
      self.hand.where(id: card.id).first.present?
    else
      false
    end
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
    self.reset_game_state!
    self.losses += 1
    self.save!
  end

  def leave_game!
    self.reset_game_state!
    self.game_id = nil
    self.save!
  end

  def reset_game_state!
    # clears all attributes relevant to gameplay, except game_id
    self.is_playing = false
    self.has_drawn = false
    self.turns_to_take = 1
    self.clear_hand!
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
    if self.username.blank?
      self.username = "Anon-#{self.object_id}"
    end
  end

  def init_stats
    UserStat.create(user_id: self.id)
  end
end
