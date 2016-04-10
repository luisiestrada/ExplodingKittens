class Stat < ActiveRecord::Base
  belongs_to :user
  belongs_to :game

  validates_presence_of :user_id
  validates_presence_of :game_id, if: ->(stat) { stat.type == 'GameStat' }
  validates_numericality_of :cards_played, :card_combos_played,
    :players_killed, only_integer: true, greater_than_or_equal_to: 0
end
