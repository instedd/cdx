class RenameEventIdColumnInTestResults < ActiveRecord::Migration
  def change
    rename_column :test_results, :event_id, :test_id
  end
end
