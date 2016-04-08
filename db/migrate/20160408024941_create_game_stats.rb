class CreateGameStats < ActiveRecord::Migration
  def change
    create_table :game_stats do |t|

    	# t.references creates integer columns game_id and user_id
    	# including index and foreign key constraint
    	t.references :game, index: true, foreign_key: true
    	t.references :user, index: true, foreign_key: true

    	t.integer :cards_played, null: false, default: 0
    	t.integer :cards_combos_played, null: false, default: 0
    	t.integer :players_killed, null: false, default: 0
    end
  end
end
