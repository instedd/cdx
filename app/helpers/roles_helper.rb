module RolesHelper
  def actions_per_resource_type
    # group_by & map: http://stackoverflow.com/a/18921086/641451
    Policy::ACTIONS.inject(Hash.new) { |hash, action|
      resource_type, action = action.split(":", 2)
      hash[resource_type] = Hash.new() unless hash.include?(resource_type)
      hash[resource_type][action] = action.underscore.humanize
      hash
    }
  end
end
