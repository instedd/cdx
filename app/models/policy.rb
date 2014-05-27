class Policy < ActiveRecord::Base
  belongs_to :user
  belongs_to :granter, class_name: 'User', foreign_key: 'granter_id'

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

    found_one ? resource : nil
  end

  private

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
