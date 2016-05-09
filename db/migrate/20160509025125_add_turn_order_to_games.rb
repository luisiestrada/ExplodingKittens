class AddTurnOrderToGames < ActiveRecord::Migration
  def change
    add_column :games, :turn_orders, :string, index: true
  end
end
