class CreateCards < ActiveRecord::Migration
  def up
    create_table :cards do |t|
      t.string :description
      t.string :card_type
      t.string :card_name
      t.integer :default_quantity
      t.integer :opponent_draw_n, default: 0
      t.boolean :skip_turn, default: false
      t.integer :view_top_deck_n, default: 0
      t.boolean :skip_draw, default: false
      t.integer :opponent_turn_n, default: 0
      t.boolean :shuffle_deck, default: false
      t.boolean :peek, default: false
      t.boolean :pair_required, default: false
      t.boolean :steal_card, default: false
      t.boolean :playable_on_opponent_turn, default: false
      t.boolean :cancel, default: false
      t.boolean :cancel_immunity, default: false

      # these are for the PlayingCard model which inherits from this
      t.integer :game_id, index: true, null: false
      t.integer :player_id, index: true
      t.string  :state, null: false, default: 'deck'

      t.timestamps
    end
  end

  def down
    drop_table :cards
  end
end
