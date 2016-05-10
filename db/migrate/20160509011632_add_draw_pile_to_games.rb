class AddDrawPileToGames < ActiveRecord::Migration
  def change
    add_column :games, :draw_pile_ids, :string, index: true
  end
end
