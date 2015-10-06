class AddLaboratoryAndInstitutionIdsToTestResults < ActiveRecord::Migration
  def change
    add_column :test_results, :laboratory_id,  :integer
    add_column :test_results, :institution_id, :integer

    add_index :test_results, :laboratory_id
    add_index :test_results, :institution_id
    add_index :test_results, :device_id
  end
end
