class RemoveAdminLevelFromLocation < ActiveRecord::Migration
  def change
    remove_column :locations, :admin_level
  end
end
