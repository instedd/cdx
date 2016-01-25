module RolesHelper
  def actions_per_resource_type
    # group_by & map: http://stackoverflow.com/a/18921086/641451
    Policy::ACTIONS.inject(Hash.new) { |hash, scopedAction|
      resource_type, action = scopedAction.split(":", 2)
      hash[resource_type] = Hash.new() unless hash.include?(resource_type)
      hash[resource_type][action] = { id: scopedAction, value: action, label: action.underscore.humanize, resource: resource_type }
      hash
    }
  end

  def resource_types
    Resource.all.map { |resource|
      {
        value: resource.name.camelize(:lower),
        label: resource.name.titleize
      }
    }
  end
end
