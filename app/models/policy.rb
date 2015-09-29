class Policy < ActiveRecord::Base
  belongs_to :user
  belongs_to :granter, class_name: 'User', foreign_key: 'granter_id'

  validates_presence_of :name, :user, :definition

  attr_accessor :allows_implicit
  validates :granter, presence: true, unless: :allows_implicit

  validate :validate_definition
  validate :validate_self_granted

  serialize :definition, JSON

  before_save :set_delegable_from_definition

  after_save    :update_computed_policies
  after_destroy :update_computed_policies

  scope :delegable, -> { where(delegable: true) }

  module Actions
    CREATE_INSTITUTION = "institution:create"
    READ_INSTITUTION =   "institution:read"
    UPDATE_INSTITUTION = "institution:update"
    DELETE_INSTITUTION = "institution:delete"

    CREATE_INSTITUTION_LABORATORY =     "institution:createLaboratory"
    CREATE_INSTITUTION_ENCOUNTER =      "institution:createEncounter"
    REGISTER_INSTITUTION_DEVICE =       "institution:registerDevice"
    REGISTER_INSTITUTION_DEVICE_MODEL = "institution:registerDeviceModel"

    READ_DEVICE_MODEL =   "deviceModel:read"
    UPDATE_DEVICE_MODEL = "deviceModel:update"
    DELETE_DEVICE_MODEL = "deviceModel:delete"

    READ_LABORATORY =   "laboratory:read"
    UPDATE_LABORATORY = "laboratory:update"
    DELETE_LABORATORY = "laboratory:delete"

    ASSIGN_DEVICE_LABORATORY = "laboratory:assignDevice" # This is not tested.

    READ_DEVICE =   "device:read"
    UPDATE_DEVICE = "device:update"
    DELETE_DEVICE = "device:delete"

    REGENERATE_DEVICE_KEY =     "device:regenerateKey" # This is not tested.
    GENERATE_ACTIVATION_TOKEN = "device:generateActivationToken" # This is not tested.
    REPORT_MESSAGE =            "device:reportMessage"

    QUERY_TEST = "test:query"
  end

  ACTIONS = [
    Actions::CREATE_INSTITUTION,
    Actions::READ_INSTITUTION,
    Actions::UPDATE_INSTITUTION,
    Actions::DELETE_INSTITUTION,
    Actions::CREATE_INSTITUTION_LABORATORY,
    Actions::READ_LABORATORY,
    Actions::UPDATE_LABORATORY,
    Actions::DELETE_LABORATORY,
    Actions::REGISTER_INSTITUTION_DEVICE,
    Actions::REGISTER_INSTITUTION_DEVICE_MODEL,
    Actions::READ_DEVICE,
    Actions::UPDATE_DEVICE,
    Actions::DELETE_DEVICE,
    Actions::READ_DEVICE_MODEL,
    Actions::UPDATE_DEVICE_MODEL,
    Actions::DELETE_DEVICE_MODEL,
    Actions::ASSIGN_DEVICE_LABORATORY,
    Actions::REGENERATE_DEVICE_KEY,
    Actions::GENERATE_ACTIVATION_TOKEN,
    Actions::QUERY_TEST,
    Actions::REPORT_MESSAGE,
  ]

  def self.superadmin
    predefined_policy "superadmin"
  end

  def self.implicit
    predefined_policy "implicit"
  end

  def self.owner(institution_id)
    predefined_policy "owner", institution_id: institution_id
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

  def validate_resource_statements(resource_statements)
    Array(resource_statements).each do |resource_statement|
      found_resource = Resource.resolve(resource_statement) rescue false
      return errors.add :definition, "has an unknown resource: `#{resource_statement}`" unless found_resource

      resource_class, resource_id, resource_query = found_resource
      return errors.add :definition, "has an invalid condition in resource: `#{resource_statement}`" unless resource_class.supports_query?(resource_query)
    end
  end

  def set_delegable_from_definition
    self.delegable = definition["delegable"]
    true
  end

  def update_computed_policies
    ComputedPolicy.update_user(user)
  end

  def self.predefined_policy(name, args={})
    policy = Policy.new
    policy.allows_implicit = true
    policy.name = name.titleize
    policy.definition = JSON.load(Erubis::Eruby.new(File.read("#{Rails.root}/app/policies/#{name}.json.erb")).result(args))
    policy.delegable = policy.definition["delegable"]
    policy
  end
end
