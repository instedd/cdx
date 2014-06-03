class RenameTestResultToEvent < ActiveRecord::Migration
  def change
    rename_table :test_results, :events
  end
end
