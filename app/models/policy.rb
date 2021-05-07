class Policy < ApplicationRecord
  belongs_to :user
  belongs_to :granter, class_name: 'User', foreign_key: 'granter_id'

  has_one :role, inverse_of: :policy

  validates_presence_of :name, :definition

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
    REGISTER_INSTITUTION_DEVICE =       "institution:registerDevice"
    REGISTER_INSTITUTION_DEVICE_MODEL = "institution:registerDeviceModel"
    CREATE_INSTITUTION_ROLE =           "institution:createRole"
    CREATE_INSTITUTION_PATIENT =        "institution:createPatient"

    READ_INSTITUTION_USERS = "institution:readUsers"

    READ_DEVICE_MODEL =      "deviceModel:read"
    UPDATE_DEVICE_MODEL =    "deviceModel:update"
    DELETE_DEVICE_MODEL =    "deviceModel:delete"
    PUBLISH_DEVICE_MODEL =   "deviceModel:publish"

    READ_PATIENT =   "patient:read"
    UPDATE_PATIENT = "patient:update"
    DELETE_PATIENT = "patient:delete"

    READ_SITE =   "site:read"
    UPDATE_SITE = "site:update"
    DELETE_SITE = "site:delete"

    ASSIGN_DEVICE_SITE = "site:assignDevice" # This is not tested.
    CREATE_SITE_ROLE = "site:createRole"
    CREATE_SITE_ENCOUNTER = "site:createEncounter"
    READ_SITE_USERS = "site:readUsers"

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

    READ_ROLE = "role:read"
    UPDATE_ROLE = "role:update"
    DELETE_ROLE = "role:delete"
    ASSIGN_USER_ROLE = "role:assignUser"
    REMOVE_USER_ROLE = "role:removeUser"

    UPDATE_USER = 'user:update'
  end

  ACTIONS = Actions.constants.map{|action| Actions.const_get(action)}

  def self.superadmin(user)
    predefined_policy "superadmin", user
  end

  def self.implicit(user)
    predefined_policy "implicit", user
  end

  def self.owner(user, institution_id, kind)
    predefined_policy "owner/#{kind}", user, institution_id: institution_id
  end

  def self.predefined_institution_roles(institution)
    predefined_roles "institution/#{institution.kind}", institution_id: institution.id, institution_name: institution.name
  end

  def self.predefined_site_roles(site)
    predefined_roles "site/#{site.institution.kind}", institution_id: site.institution.id, site_id: site.id, site_name: site.name
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
    self.user_id && self.user_id == self.granter_id
  end

  def to_computed_policies
    ComputedPolicy::PolicyComputer.new.compute_for(self)
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
      if resource_statements && !resource_statements.empty?
        validate_resource_statements(resource_statements)
      else
        return errors.add :definition, "is missing resource in statement"
      end

      except_statements = statement["except"]
      if except_statements
        validate_resource_statements(except_statements)
      end

      ["delegable", "includeSubsites"].each do |key|
        statement_value = statement[key]
        if !statement_value.nil?
          if statement_value != true && statement_value != false
            return errors.add :definition, "has an invalid #{key} value: `#{statement_value}`"
          end
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
    if user
      ComputedPolicy.update_user(user)
    elsif role
      role.update_computed_policies
    end
  end

  def self.predefined_policy(name, user, args={})
    policy = Policy.new
    policy.allows_implicit = true
    policy.name = name.titleize
    policy.definition = JSON.load(Erubis::Eruby.new(predefined_policy_template(name)).result(args))
    policy.user = user
    policy
  end

  def self.predefined_roles(name, args={})
    roles_json = JSON.load(Erubis::Eruby.new(predefined_policy_template("roles/#{name}")).result(args))
    roles_json.map do |role_json|
      role = Role.new
      role.name = role_json["name"]
      role.key = role_json["key"]

      policy = Policy.new
      policy.allows_implicit = true
      policy.name = name.titleize
      policy.definition = role_json["policy"]
      role.policy = policy

      role
    end
  end

  def self.predefined_policy_template(name)
    @templates ||= {}
    @templates[name] ||= File.read("#{Rails.root}/app/policies/#{name}.json.erb")
  end
end
