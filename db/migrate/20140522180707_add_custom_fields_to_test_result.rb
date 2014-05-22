class AddCustomFieldsToTestResult < ActiveRecord::Migration
  def change
    add_column :test_results, :custom_fields, :text
  end
end
