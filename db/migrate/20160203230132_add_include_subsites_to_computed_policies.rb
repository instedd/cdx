class AddIncludeSubsitesToComputedPolicies < ActiveRecord::Migration
  def change
    add_column :computed_policies, :include_subsites, :boolean, default: false
  end
end
