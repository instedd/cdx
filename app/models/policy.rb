class Policy < ActiveRecord::Base
  belongs_to :user
  belongs_to :granter, class_name: 'User', foreign_key: 'granter_id'

  validates_presence_of :name, :granter, :user, :definition
  validate :validate_definition
  validate :validate_owner_permissions

  serialize :definition, JSON

  before_save :set_delegable_from_definition

  module Actions
    PREFIX = "cdxp"

    CREATE_INSTITUTION = "#{PREFIX}:createInstitution"
    READ_INSTITUTION = "#{PREFIX}:readInstitution"
    UPDATE_INSTITUTION = "#{PREFIX}:updateInstitution"
    DELETE_INSTITUTION = "#{PREFIX}:deleteInstitution"

    CREATE_INSTITUTION_LABORATORY = "#{PREFIX}:createInstitutionLaboratory"
    READ_LABORATORY = "#{PREFIX}:readLaboratory"
    UPDATE_LABORATORY = "#{PREFIX}:updateLaboratory"
    DELETE_LABORATORY = "#{PREFIX}:deleteLaboratory"

    CREATE_INSTITUTION_ENCOUNTER = "#{PREFIX}:createInstitutionEncounter"

    REGISTER_INSTITUTION_DEVICE = "#{PREFIX}:registerInstitutionDevice"
    READ_DEVICE = "#{PREFIX}:readDevice"
    UPDATE_DEVICE = "#{PREFIX}:updateDevice"
    DELETE_DEVICE = "#{PREFIX}:deleteDevice"
    ASSIGN_DEVICE_LABORATORY = "#{PREFIX}:assignDeviceLaboratory" # This is not tested.
    REGENERATE_DEVICE_KEY = "#{PREFIX}:regenerateDeviceKey" # This is not tested.
    GENERATE_ACTIVATION_TOKEN = "#{PREFIX}:generateActivationToken" # This is not tested.
    SUPPORT_DEVICE = "#{PREFIX}:supportDevice" # This is not tested.
    QUERY_TEST = "#{PREFIX}:queryTest"
    REPORT_MESSAGE = "#{PREFIX}:reportMessage"
  end

  ACTIONS = [
    Actions::READ_INSTITUTION,
    Actions::UPDATE_INSTITUTION,
    Actions::DELETE_INSTITUTION,
    Actions::CREATE_INSTITUTION_LABORATORY,
    Actions::READ_LABORATORY,
    Actions::UPDATE_LABORATORY,
    Actions::DELETE_LABORATORY,
    Actions::REGISTER_INSTITUTION_DEVICE,
    Actions::READ_DEVICE,
    Actions::UPDATE_DEVICE,
    Actions::DELETE_DEVICE,
    Actions::ASSIGN_DEVICE_LABORATORY,
    Actions::REGENERATE_DEVICE_KEY,
    Actions::GENERATE_ACTIVATION_TOKEN,
    Actions::SUPPORT_DEVICE,
    Actions::QUERY_TEST,
    Actions::REPORT_MESSAGE,
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

  def self.can? action, resource, user, policies=nil
    check_all(action, resource, user, (policies || user.policies), Set.new, false).present?
  end

  def self.cannot? action, resource, user
    !can? action, resource, user
  end

  def self.can_delegate? action, resource, granter
    self.can? action, resource, granter, granter.policies.delegable
  end

  def self.authorize action, resource, user, policies=nil, users_so_far = Set.new
    check_all action, resource, user, (policies || user.policies), users_so_far, true
  end

  def implicit?
    self.granter_id == nil
  end

  def self_granted?
    self.user_id == self.granter_id
  end

  def check action, resource, user, check_conditions=false, users_so_far=Set.new
    allowed = []
    denied = []
    definition["statement"].each do |statement|
      match = check_statement(statement, action, resource, user, users_so_far, check_conditions)
      if match
        if statement["effect"] == "allow"
          allowed << match
        else
          denied << match
        end
      end
    end
    return allowed, denied
  end

  def self.check_all action, resource, user, policies, users_so_far, check_conditions
    allowed = []
    denied = []

    policies.each do |policy|
      match_allowed, match_denied = policy.check(action, resource, user, check_conditions, users_so_far)
      allowed += match_allowed
      denied += match_denied
    end

    classes = denied.select { |klass| klass.is_a?(Class) }
    allowed -= classes
    denied -= classes

    load_results allowed, denied, !check_conditions
  end

  private

  def check_statement statement, action, resource, user, users_so_far, check_conditions
    return nil unless action_matches?(action, statement["action"])

    resource = apply_resource_filters(resource, statement["resource"])
    return nil unless resource

    if (condition = statement["condition"])
      resource = apply_condition(resource, condition, user, check_conditions)
      return nil unless resource
    end

    # Check that the granter's policies allow the action on the resource,
    # but only if the policy is not implicit (or superadmin)
    if !implicit? && !users_so_far.include?(granter)
      users_so_far.add granter
      granter_result = Policy.check_all action, resource, granter, granter.policies.delegable, users_so_far, check_conditions
      users_so_far.delete granter

      return nil unless granter_result

      resource = granter_result
    end

    resource
  end

  def self.load_results allowed, denied, keep_classes_if_empty=false
    [allowed, denied].each do |resources|
      resources.map! do |resource|
        if resource.is_a?(Class)
          all = resource.all
          if keep_classes_if_empty && all.empty?
            resource
          else
            all
          end
        else
          resource
        end
      end
      resources.flatten!
      resources.uniq!
    end

    result = allowed - denied
    result.delete nil
    result
  end

  def validate_owner_permissions
    return errors.add :owner, "permission can't be self granted" if self_granted?
    return errors.add :owner, "permission granter can't be nil" if implicit?

    resources = definition["statement"].each do |statement|
      Array(statement["action"]).each do |action|
        Array(statement["resource"]).each do |resource_matcher|
          match = Resource.find(resource_matcher)
          if match
            resources = Array(match)
            resources.each do |resource|
              unless self.class.can_delegate?(action, resource, granter)
                return errors.add :owner, "can't delegate permission over #{resource_matcher}"
              end
            end
          end
        end
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
        if effect != "allow" && effect != "deny"
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

      resource_statements = statement["resource"]
      if resource_statements
        Array(resource_statements).each do |resource_statement|
          found_resource = Resource.all.any? do |resource|
            resource.filter_by_resource(resource_statement)
          end
          unless found_resource
            return errors.add :definition, "has an unknown resource: `#{resource_statement}`"
          end
        end
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

  def action_matches? action, action_filters
    action_filters = Array(action_filters)
    action_filters.any? do |action_filter|
      action_filter == "*" || action_filter == action
    end
  end

  def apply_resource_filters resource, resource_filters
    return unless resource
    resource_filters = Array(resource_filters)
    resource_filters.each do |resource_filter|
      if resource_filter == "*"
        return resource
      end

      new_resource = if resource.is_a?(ActiveRecord::Relation) || resource.is_a?(Array)
        resource.to_a.map do |resource|
          resource.filter_by_resource(resource_filter)
        end.delete_if &:nil?
      else
        resource.filter_by_resource(resource_filter)
      end
      if new_resource.present?
        return new_resource
      end
    end

    nil
  end

  def apply_condition resource, condition, user, check_conditions
    condition.each do |key, value|
      case key
      when "is_owner"
        resource = if resource.is_a? Array
          resource.map do |resource|
            resource.filter_by_owner(user, check_conditions)
          end
        else
          resource.filter_by_owner(user, check_conditions)
        end
      end
    end

    resource
  end

  def self.predefined_policy name
    policy = Policy.new
    policy.name = name
    policy.definition = JSON.load File.read("#{Rails.root}/app/policies/#{name}.json")
    policy.delegable = policy.definition["delegable"]
    policy
  end
end
