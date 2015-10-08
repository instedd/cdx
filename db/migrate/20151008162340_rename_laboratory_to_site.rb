class RenameLaboratoryToSite < ActiveRecord::Migration
  def change
    rename_column :computed_policies, :condition_site_id, :condition_site_id
    rename_column :computed_policy_exceptions, :condition_site_id, :condition_site_id
    rename_column :devices, :site_id, :site_id
    rename_table :sites, :sites
    rename_column :test_results, :site_id, :site_id
  end
end
