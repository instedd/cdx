class Policy < ActiveRecord::Base
  belongs_to :user
  belongs_to :granter, class_name: 'User', foreign_key: 'granter_id'

  validates_presence_of :name, :user, :definition

  attr_accessor :allows_implicit
  validates :granter, presence: true, unless: :allows_implicit

  validate :validate_definition
  validate :validate_self_granted

  serialize :definition, JSON

  after_save    :update_computed_policies
  after_destroy :update_computed_policies

  module Actions
    CREATE_INSTITUTION = "institution:create"
    READ_INSTITUTION =   "institution:read"
    UPDATE_INSTITUTION = "institution:update"
    DELETE_INSTITUTION = "institution:delete"

    CREATE_INSTITUTION_SITE =           "institution:createSite"
    CREATE_INSTITUTION_ENCOUNTER =      "institution:createEncounter"
    REGISTER_INSTITUTION_DEVICE =       "institution:registerDevice"
    REGISTER_INSTITUTION_DEVICE_MODEL = "institution:registerDeviceModel"

    READ_DEVICE_MODEL =      "deviceModel:read"
    UPDATE_DEVICE_MODEL =    "deviceModel:update"
    DELETE_DEVICE_MODEL =    "deviceModel:delete"
    PUBLISH_DEVICE_MODEL =   "deviceModel:publish"

    READ_SITE =   "site:read"
    UPDATE_SITE = "site:update"
    DELETE_SITE = "site:delete"

    ASSIGN_DEVICE_SITE = "site:assignDevice" # This is not tested.

    READ_DEVICE =   "device:read"
    UPDATE_DEVICE = "device:update"
    DELETE_DEVICE = "device:delete"
    SUPPORT_DEVICE = "device:support"

    REGENERATE_DEVICE_KEY =     "device:regenerateKey" # This is not tested.
    GENERATE_ACTIVATION_TOKEN = "device:generateActivationToken" # This is not tested.
    REPORT_MESSAGE =            "device:reportMessage"

    QUERY_TEST = "testResult:query"
    PII_TEST =   "testResult:pii"

    READ_ENCOUNTER =   "encounter:read"
    UPDATE_ENCOUNTER = "encounter:update"
    PII_ENCOUNTER =    "encounter:pii"

    MEDICAL_DASHBOARD = "testResult:medicalDashboard"
  end

  ACTIONS = Actions.constants.map{|action| Actions.const_get(action)}

  def self.superadmin(user)
    predefined_policy "superadmin", user
  end

  def self.implicit(user)
    predefined_policy "implicit", user
  end

  def self.owner(user, institution_id, kind)
    predefined_policy "owner_#{kind}", user, institution_id: institution_id
  end

  def self.can? action, resource, user, policies=nil
    ComputedPolicy.can?(action, resource, user)
  end

  def self.cannot? action, resource, user, policies=nil
    !can? action, resource, user, policies
  end

  def self.can_delegate? action, resource, granter
    ComputedPolicy.can_delegate?(action, resource, granter)
  end

  def self.authorize action, resource, user, policies=nil
    ComputedPolicy.authorize(action, resource, user)
  end

  def self.condition_resources_for(action, resource, user)
    ComputedPolicy.condition_resources_for(action, resource, user)
  end

  def self.authorized_users(action, resource)
    ComputedPolicy.authorized_users(action, resource)
  end

  def implicit?
    self.granter_id == nil
  end

  def self_granted?
    self.user_id == self.granter_id
  end

  # Not evaluated as part of validations in ActiveModel lifecycle
  def validate_owner_permissions
    return if implicit?

    resources = definition["statement"].each do |statement|
      Array(statement["action"]).each do |action|
        Array(statement["resource"]).each do |resource_matcher|
          unless self.class.can_delegate?(action, resource_matcher, granter)
            return errors.add :owner, "can't delegate permission over #{resource_matcher}"
          end
        end
      end
    end

    true
  end

  private

  def validate_self_granted
    return errors.add :owner, "permission can't be self granted" if self_granted?
  end

  def validate_definition
    unless definition["statement"]
      return errors.add :definition, "is missing a statement"
    end

    definition["statement"].each do |statement|
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
        validate_resource_statements(resource_statements)
      else
        return errors.add :definition, "is missing resource in statement"
      end

      except_statements = statement["except"]
      if except_statements
        validate_resource_statements(except_statements)
      end

      delegable = statement["delegable"]
      if !delegable.nil?
        if delegable != true && delegable != false
          return errors.add :definition, "has an invalid delegable value: `#{delegable}`"
        end
      end
    end
  end

  def validate_resource_statements(resource_statements)
    Array(resource_statements).each do |resource_statement|
      found_resource = Resource.resolve(resource_statement) rescue false
      return errors.add :definition, "has an unknown resource: `#{resource_statement}`" unless found_resource

      resource_class, resource_id, resource_query = found_resource
      return errors.add :definition, "has an invalid condition in resource: `#{resource_statement}`"    unless resource_class.supports_query?(resource_query)
      return errors.add :definition, "has unsupported identifier in resource: `#{resource_statement}`"  unless resource_class.supports_identifier?(resource_id)
    end
  end

  def update_computed_policies
    ComputedPolicy.update_user(user)
  end

  def self.predefined_policy(name, user, args={})
    policy = Policy.new
    policy.allows_implicit = true
    policy.name = name.titleize
    policy.definition = JSON.load(Erubis::Eruby.new(predefined_policy_template(name)).result(args))
    policy.user = user
    policy
  end

  def self.predefined_policy_template(name)
    @templates ||= {}
    @templates[name] ||= File.read("#{Rails.root}/app/policies/#{name}.json.erb")
  end
end
