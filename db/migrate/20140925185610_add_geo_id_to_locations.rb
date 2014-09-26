class AddGeoIdToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :geo_id, :string
  end
end
