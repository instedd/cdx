class RemoveDelegableFromPolicies < ActiveRecord::Migration
  def change
    remove_column :policies, :delegable, :boolean, default: false
  end
end
