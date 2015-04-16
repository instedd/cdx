class DropLocationsTable < ActiveRecord::Migration
  def up
    drop_table :locations
  end

  def down
    create_table :locations do |t|
      t.string   "name"
      t.integer  "parent_id"
      t.integer  "lft"
      t.integer  "rgt"
      t.float    "lat"
      t.float    "lng"
      t.integer  "depth"
      t.integer  "admin_level"
      t.string   "geo_id"

      t.timestamps
    end

    add_index :locations, :lft
    add_index :locations, :rgt
    add_index :locations, :depth
    add_index :locations, :parent_id
  end
end
