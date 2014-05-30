class AddEventIdToTestResults < ActiveRecord::Migration
  def change
    add_column :test_results, :event_id, :string
  end
end
