class GameStat < ActiveRecord::Base
	belongs_to :user
	belongs_to :game

	validates_presence_of :user_id, :game_id

	validates_numericality_of :cards_played, :cards_combos_played, 
		:players_killed, only_integer: true, greater_than_or_equal_to: 0
end