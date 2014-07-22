class AddAdminLevelToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :admin_level, :integer
  end
end
