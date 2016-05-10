class AddRoomNameToGame < ActiveRecord::Migration
  def change
    add_column :games, :room_name, :string
  end
end
