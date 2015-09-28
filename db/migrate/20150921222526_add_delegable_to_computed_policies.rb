class AddDelegableToComputedPolicies < ActiveRecord::Migration
  def change
    add_column :computed_policies, :delegable, :boolean, default: false
  end
end
