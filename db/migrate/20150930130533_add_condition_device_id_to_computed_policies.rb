class AddConditionDeviceIdToComputedPolicies < ActiveRecord::Migration
  def change
    add_column :computed_policies,          :condition_device_id, :integer, null: true
    add_column :computed_policy_exceptions, :condition_device_id, :integer, null: true
  end
end
