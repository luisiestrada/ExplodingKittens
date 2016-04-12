class CreateUserStats < ActiveRecord::Migration
  def change
    create_table :user_stats do |t|
      t.integer :user_id, index: true
      t.integer :wins, null: false, default: 0
      t.integer :losses, null: false, default: 0
      t.integer :cards_played, null: false, default: 0
      t.integer :card_combos_played, null: false, default: 0
      t.integer :players_killed, null: false, default: 0
    end
  end
end
