class RemoveInstitutionIdFromTestResults < ActiveRecord::Migration
  def up
    remove_column :test_results, :institution_id
  end
  def down
    add_column :test_results, :institution_id, :integer
  end
end
