class AddLocationToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :location_geoid, :string, limit: 60
    add_column :patients, :lat, :float
    add_column :patients, :lng, :float
    add_column :patients, :address, :string
  end
end
