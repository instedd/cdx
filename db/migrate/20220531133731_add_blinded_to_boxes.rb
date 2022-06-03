class AddBlindedToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :blinded, :boolean, default: false, null: false
  end
end
