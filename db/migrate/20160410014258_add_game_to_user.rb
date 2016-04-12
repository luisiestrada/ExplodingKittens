class AddGameToUser < ActiveRecord::Migration
  def change
    add_column :users, :game_id, :integer, index: true
  end
end
