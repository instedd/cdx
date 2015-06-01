class RenameDeviceEventsEventsToDeviceEventsTestResults < ActiveRecord::Migration
  def change
    rename_table :device_events_events, :device_events_test_results
  end
end
