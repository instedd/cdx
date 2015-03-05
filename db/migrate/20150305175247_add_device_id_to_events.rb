class AddDeviceIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :device_id, :integer
  end
end
