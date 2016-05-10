class AddIsPlayingToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_playing, :boolean, default: false, null: false
  end
end
