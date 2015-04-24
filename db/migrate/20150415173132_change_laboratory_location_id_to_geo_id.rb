class ChangeLaboratoryLocationIdToGeoId < ActiveRecord::Migration
  def change
    add_column    :laboratories, :location_geoid, :string, limit: 60
    remove_column :laboratories, :location_id, :integer
  end
end
