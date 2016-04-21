class SetSiteIdInDeviceMessages < ActiveRecord::Migration
  def up
    connection.execute <<-SQL
      UPDATE device_messages
      SET site_id = (SELECT site_id FROM devices WHERE devices.id = device_messages.device_id)
    SQL
  end
end
