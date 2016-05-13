class AddCurrentPLayerTurnToGame < ActiveRecord::Migration
  def change
    add_column :games, :current_turn_player_id, :integer, index: true, null: true
  end
end
