class RenameLaboratoryToSite < ActiveRecord::Migration
  def change
    rename_column :computed_policies, :condition_laboratory_id, :condition_site_id
    rename_column :computed_policy_exceptions, :condition_laboratory_id, :condition_site_id
    rename_column :devices, :laboratory_id, :site_id
    rename_table :laboratories, :sites
    rename_column :test_results, :laboratory_id, :site_id
  end
end
