class RemoveLocationFromPolicies < ActiveRecord::Migration
  class Policy < ActiveRecord::Base
    serialize :definition, JSON
  end

  def up
    Policy.find_each do |policy|
      definition = policy.definition
      statements = definition["statement"]
      statements.delete_if { |statement| statement["resource"] == "cdxp:location" }
      policy.save(validate: false)
    end
  end

  def down
  end
end
