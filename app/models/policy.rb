class Policy < ActiveRecord::Base
  belongs_to :user
  belongs_to :granter, class_name: 'User', foreign_key: 'granter_id'

  validates_presence_of :name
  validate :validate_definition
  validate :validate_owner_permissions

  serialize :definition, JSON

  before_save :set_delegable_from_definition

  module Actions
    PREFIX = "cdpx"

    CREATE_INSTITUTION = "#{PREFIX}:createInstitution"
    READ_INSTITUTION = "#{PREFIX}:readInstitution"
    UPDATE_INSTITUTION = "#{PREFIX}:updateInstitution"
    DELETE_INSTITUTION = "#{PREFIX}:deleteInstitution"

    CREATE_LABORATORY = "#{PREFIX}:createLaboratory"
    READ_LABORATORY = "#{PREFIX}:readLaboratory"
    UPDATE_LABORATORY = "#{PREFIX}:updateLaboratory"
    DELETE_LABORATORY = "#{PREFIX}:deleteLaboratory"

    CREATE_DEVICE = "#{PREFIX}:createDevice"
    READ_DEVICE = "#{PREFIX}:readDevice"
    UPDATE_DEVICE = "#{PREFIX}:updateDevice"
    DELETE_DEVICE = "#{PREFIX}:deleteDevice"
    REGENERATE_DEVICE_KEY = "#{PREFIX}:regenerateDeviceKey"
  end

  ACTIONS = [
    Actions::READ_INSTITUTION, Actions::UPDATE_INSTITUTION, Actions::DELETE_INSTITUTION,
    Actions::CREATE_DEVICE, Actions::READ_DEVICE, Actions::UPDATE_DEVICE, Actions::DELETE_DEVICE, Actions::REGENERATE_DEVICE_KEY,
  ]

  def self.delegable
    where(delegable: true)
  end

  def self.superadmin
    predefined_policy "superadmin"
  end

  def self.implicit
    predefined_policy "implicit"
  end

  def self.check_all(action, resource, policies, user)
    resources = policies.map do |policy|
      policy.check action, resource, user
    end
    resources.compact!
    if resources.empty?
      nil
    else
      resources.map! do |resource|
        resource.is_a?(Class) ? resource.all : resource
      end
      resources.flatten!
      resources.uniq!
      resources
    end
  end

  def check(action, resource, user)
    found_one = false

    definition["statement"].each do |statement|
      return nil unless action_matches?(action, statement["action"])

      new_resource = apply_resource_filters(resource, statement["resource"])
      if new_resource
        found_one = true
        resource = new_resource
        if (condition = statement["condition"])
          resource = apply_condition(resource, condition, user)
        end
      end
    end

    return nil unless found_one && resource

    # Check that the granter's policies allow the action on the resource,
    # but only if the user is not the same as the granter (like implicit and superadmin policies)
    unless self_granted?
      granter_result = Policy.check_all action, resource, granter.policies.delegable, granter
      return nil unless granter_result

      resource = granter_result
    end

    resource
  end

  def self_granted?
    self.user_id == self.granter_id
  end

  private

  def validate_owner_permissions
    unless self_granted?
      resources = definition["statement"].map do |statement|
        Array(statement["action"]).map do |action|
          Array(statement["resource"]).map do |resource_matcher|
            resources = Array(Resource.find(resource_matcher))
            resources.map do |resource|
              Policy.check_all(action, resource, granter.policies.delegable, granter)
            end
          end
        end
      end.flatten.compact
      if resources.empty?
        return errors.add :owner, "can't delegate permission"
      end
    end
    true
  end

  def validate_definition
    unless definition["statement"]
      return errors.add :definition, "is missing a statement"
    end

    definition["statement"].each do |statement|
      effect = statement["effect"]
      if effect
        if effect != "allow" && effect != "disallow"
          return errors.add :definition, "has an invalid effect: `#{effect}`"
        end
      else
        return errors.add :definition, "is missing efect in statement"
      end

      actions = statement["action"]
      if actions
        actions = Array(actions)
        actions.each do |action|
          next if action == "*"

          unless ACTIONS.include?(action)
            return errors.add :definition, "has an unknown action: `#{action}`"
          end
        end
      else
        return errors.add :definition, "is missing action in statemenet"
      end

      resources = statement["resource"]
      if resources
        # TODO: validate resources
      else
        return errors.add :definition, "is missing resource in statement"
      end
    end

    delegable = definition["delegable"]
    if !delegable.nil?
      if delegable != true && delegable != false
        return errors.add :definition, "has an invalid delegable value: `#{delegable}`"
      end
    else
      return errors.add :definition, "is missing delegable attribute"
    end
  end

  def set_delegable_from_definition
    self.delegable = definition["delegable"]
    true
  end

  def action_matches?(action, action_filters)
    action_filters = Array(action_filters)
    action_filters.any? do |action_filter|
      action_filter == "*" || action_filter == action
    end
  end

  def apply_resource_filters(resource, resource_filters)
    resource_filters = Array(resource_filters)
    resource_filters.each do |resource_filter|
      if resource_filter == "*"
        return resource
      end

      new_resource = resource.filter_by_resource(resource_filter)
      if new_resource
        return new_resource
      end
    end

    nil
  end

  def apply_condition(resource, condition, user)
    condition.each do |key, value|
      case key
      when "is_owner"
        resource = resource.filter_by_owner(user)
      end
    end

    resource
  end

  def self.predefined_policy(name)
    policy = Policy.new
    policy.name = name
    policy.definition = JSON.load File.read("#{Rails.root}/app/policies/#{name}.json")
    policy.delegable = policy.definition["delegable"]
    policy
  end
end
