class DropAllowColumnFromComputedPolicies < ActiveRecord::Migration
  def change
    remove_column :computed_policies, :allow, :boolean, default: true
  end
end
