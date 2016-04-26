class AddAllowsManualEntryToSite < ActiveRecord::Migration
  def change
    add_column :sites, :allows_manual_entry, :boolean
  end
end
