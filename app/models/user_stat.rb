class UserStat < Stat
  belongs_to :user

  validates_presence_of :user_id
  validates_numericality_of :wins, :losses, :cards_played, :card_combos_played,
    :players_killed, only_integer: true, greater_than_or_equal_to: 0

  def games_played
    self.wins + self.losses
  end

  def win_loss_ratio
    if self.losses == 0 && self.wins == 0
      0.0
    elsif self.losses == 0
      100.0
    else
      self.wins / self.games_played
    end
  end
end
