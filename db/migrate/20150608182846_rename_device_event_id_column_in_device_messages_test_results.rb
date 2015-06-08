class RenameDeviceEventIdColumnInDeviceMessagesTestResults < ActiveRecord::Migration
  def change
    rename_column :device_messages_test_results, :device_event_id, :device_message_id
  end
end
