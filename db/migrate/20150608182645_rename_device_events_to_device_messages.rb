class RenameDeviceEventsToDeviceMessages < ActiveRecord::Migration
  def change
    rename_table :device_events, :device_messages
  end
end
