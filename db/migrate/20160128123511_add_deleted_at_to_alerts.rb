class AddDeletedAtToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :deleted_at, :datetime
    add_index :alerts, :deleted_at
  end
end
