class AddSensitiveDataToTestResults < ActiveRecord::Migration
  def change
    add_column :test_results, :sensitive_data, :binary
    rename_column(:test_results, :data, :raw_data)
  end
end
