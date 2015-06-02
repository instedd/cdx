class RenameEventsToTestResults < ActiveRecord::Migration
  def change
    rename_table :events, :test_results
  end
end
