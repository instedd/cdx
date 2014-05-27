class Policy < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :name

  serialize :definition, JSON

  class CheckResult
    attr_reader :resources

    def initialize(allowed, resources)
      @allowed = allowed
      @resources = resources
    end

    def allowed?
      @allowed
    end
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
      CheckResult.new(false, nil)
    else
      CheckResult.new(true, resources.flatten)
    end
  end

  def check(action, resource, user)
    conditions = []

    definition["statement"].each do |statement|
      if action_matches?(action, statement["action"]) &&
        resource_matches?(resource, statement["resource"])
        conditions << statement["condition"] if statement["condition"]
      else
        return nil
      end
    end

    apply_conditions(resource, conditions, user)
  end

  private

  def action_matches?(action, action_filter)
    action_filter == "*"
  end

  def resource_matches?(resource, resource_filter)
    resource_filter == "*"
  end

  def apply_conditions(resource, conditions, user)
    conditions.each do |condition|
      condition.each do |key, value|
        case key
        when "is_owner"
          resource = resource.filter_by_owner(user)
        end
      end
    end

    resource
  end

  def self.predefined_policy(name)
    policy = Policy.new
    policy.definition = JSON.load File.read("#{Rails.root}/app/policies/#{name}.json")
    policy.delegable = policy.definition["delegable"]
    policy
  end
end
