class AddTimestampsInDeviceTimeZoneToUsers < ActiveRecord::Migration
  def change
    add_column :users, :timestamps_in_device_time_zone, :boolean, default: false
  end
end
