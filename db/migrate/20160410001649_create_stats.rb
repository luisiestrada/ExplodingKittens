class CreateStats < ActiveRecord::Migration
  def change
    drop_table :user_stats

    # These used to belong to user_stats. Moving them to the users table
    add_column :users, :wins, :integer, null: false, default: 0
    add_column :users, :losses, :integer, null: false, default: 0

    # This table will be shared by user_stats & game_stats
    create_table :stats do |t|
      t.integer :user_id, index: true, null: false
      t.integer :game_id, index: true
      t.string  :type, null: false, index: true
      t.integer :cards_played, null: false, default: 0
      t.integer :card_combos_played, null: false, default: 0
      t.integer :players_killed, null: false, default: 0
    end
  end
end
