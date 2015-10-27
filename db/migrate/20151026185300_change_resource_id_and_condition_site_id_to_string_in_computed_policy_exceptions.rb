class ChangeResourceIdAndConditionSiteIdToStringInComputedPolicyExceptions < ActiveRecord::Migration
  def change
    change_column :computed_policy_exceptions, :resource_id, :string
    change_column :computed_policy_exceptions, :condition_site_id, :string
  end
end
