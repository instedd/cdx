class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string   :name
      t.integer  :parent_id
      t.integer  :lft
      t.integer  :rgt
      t.float    :lat
      t.float    :lng
      t.integer  :depth

      t.timestamps
    end

    add_index :locations, :lft
    add_index :locations, :rgt
    add_index :locations, :depth
    add_index :locations, :parent_id
  end
end
