class RemoveSiteIdFromAlerts < ActiveRecord::Migration
  def change
    remove_column :alerts, :site_id, :integer
  end
end
