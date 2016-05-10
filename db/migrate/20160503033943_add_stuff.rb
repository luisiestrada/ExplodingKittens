class AddStuff < ActiveRecord::Migration
  def change
    add_column :games, :current_turn_player_index, :integer, null: true
    add_column :users, :has_drawn, :boolean, default: false
    add_column :users, :turns_to_take, :integer, default: 1

    rename_column :cards, :opponent_draw_n, :opponent_skip_turn_n
  end
end
