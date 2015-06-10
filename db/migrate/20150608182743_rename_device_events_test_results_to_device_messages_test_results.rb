class RenameDeviceEventsTestResultsToDeviceMessagesTestResults < ActiveRecord::Migration
  def change
    rename_table :device_events_test_results, :device_messages_test_results
  end
end
