class UserStat < Stat
  belongs_to :user

  validates_presence_of :user_id
  validates_numericality_of :cards_played, :card_combos_played,
    :players_killed, only_integer: true, greater_than_or_equal_to: 0
end
