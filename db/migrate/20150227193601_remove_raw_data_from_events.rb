class RemoveRawDataFromEvents < ActiveRecord::Migration
  def change
    remove_column :events, :raw_data, :binary
    remove_column :events, :device_id, :integer
    remove_column :events, :index_failed, :boolean
    remove_column :events, :index_failure_reason, :text
  end
end
