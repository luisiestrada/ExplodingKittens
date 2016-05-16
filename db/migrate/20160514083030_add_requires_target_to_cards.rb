class AddRequiresTargetToCards < ActiveRecord::Migration
  def change
    add_column :cards, :requires_target, :boolean, default: false
  end
end
