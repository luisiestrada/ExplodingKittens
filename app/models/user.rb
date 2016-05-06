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
