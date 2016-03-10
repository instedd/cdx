class ChangeResourceIdAndConditionSiteIdToStringInComputedPolicies < ActiveRecord::Migration
  def change
    change_column :computed_policies, :resource_id, :string
    change_column :computed_policies, :condition_site_id, :string
  end
end
