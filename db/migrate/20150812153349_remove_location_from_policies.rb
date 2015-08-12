class RemoveLocationFromPolicies < ActiveRecord::Migration
  def up
    Policy.all.each do |policy|
      definition = policy.definition
      statements = definition["statement"]
      statements.delete_if { |statement| statement["resource"] == "cdxp:location" }
      policy.save(validate: false)
    end
  end

  def down
  end
end
