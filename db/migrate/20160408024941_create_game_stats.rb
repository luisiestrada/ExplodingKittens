class CreateGameStats < ActiveRecord::Migration
  def change
    create_table :game_stats do |t|
    	t.integer :game_id, null: false, index: true
    	t.integer :user_id, null: false, index: true
    	t.integer :cards_played, null: false, default: 0
    	t.integer :cards_combos_played, null: false, default: 0
    	t.integer :players_killed, null: false, default: 0

    	# foreign key on game_id column of game_stats table
    	add_foreign_key :game_stats, :game
    	add_foreign_key :game_stats, :user
    end
  end
end
