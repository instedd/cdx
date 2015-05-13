class AddIndexFailureDataToDeviceEvents < ActiveRecord::Migration
  def change
    add_column :device_events, :index_failure_data, :text
  end
end
