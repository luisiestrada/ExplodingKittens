class AddHostUserToGame < ActiveRecord::Migration
  def change
    add_column :games, :host_id, :integer, index: true, null: true, default: nil
  end
end
