class RenameIndexedFieldsToCoreFields < ActiveRecord::Migration
  def change
    rename_column :test_results, :indexed_fields, :core_fields
    rename_column :patients, :indexed_fields, :core_fields
    rename_column :samples, :indexed_fields, :core_fields
    rename_column :encounters, :indexed_fields, :core_fields
  end
end
