class CreatePlayingCards < ActiveRecord::Migration
  def change
    create_table :playing_cards do |t|
      t.integer :game_id, index: true, null: false
      t.integer :player_id, index: true
      t.state   :string, null: false, default: 'deck'
    end
  end
end
