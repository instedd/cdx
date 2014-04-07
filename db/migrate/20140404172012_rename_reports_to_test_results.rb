class RenameReportsToTestResults < ActiveRecord::Migration
  def change
    rename_table :reports, :test_results
  end
end
