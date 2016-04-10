class CreateGame < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.boolean :active, null: false, default: false
      t.integer :winner_id, index: true
      t.timestamps null: false
    end
  end
end
