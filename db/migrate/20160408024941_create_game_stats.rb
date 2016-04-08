class CreateGameStats < ActiveRecord::Migration
  def change
    create_table :game_stats do |t|
    	t.int :game_id, null: false, index: true
    	t.int :user_id, null: false, index: true
    	t.int :cards_played, null: false, default: 0
    	t.int :cards_combos_played, null: false, default: 0
    	t.int :players_killed, null: false, default: 0

    	# foreign key on game_id column of game_stats table
    	add_foreign_key :game_stats, :game
    	add_foreign_key :game_stats, :user
    end
  end
end
