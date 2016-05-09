class AddTurnOrderToGames < ActiveRecord::Migration
  def change
    add_column :games, :turn_orders, :string, index: true
    remove_column :games, :current_turn_player_id
  end
end
