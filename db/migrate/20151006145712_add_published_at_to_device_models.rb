class AddPublishedAtToDeviceModels < ActiveRecord::Migration

  def change
    add_column :device_models, :published_at, :datetime, null: true
    add_index :device_models, :published_at
    connection.execute("UPDATE device_models SET published_at = NOW() WHERE published_at IS NULL")
  end

end
