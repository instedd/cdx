class RenameEventIdColumnInDeviceEventsTestResults < ActiveRecord::Migration
  def change
    rename_column :device_events_test_results, :event_id, :test_result_id
  end
end
