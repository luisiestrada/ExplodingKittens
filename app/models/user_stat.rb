class UserStat < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user_id
  validates_numericality_of :wins, :losses, :cards_played, :card_combos_played,
    :players_killed, only_integer: true, greater_than_or_equal_to: 0

  def games_played
    self.wins + self.losses
  end

  def win_loss_ratio
    self.wins / self.losses
  end
end
