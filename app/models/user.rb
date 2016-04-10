class User < ActiveRecord::Base
  belongs_to :game
  has_one :stats, class_name: UserStat

  validates_presence_of :email, :password
  validates_numericality_of :wins, :losses,
    only_integer: true, greater_than_or_equal_to: 0

  before_create :generate_anon_username
  after_create :init_stats

  def games_played
    self.wins + self.losses
  end

  def win_loss_ratio
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
