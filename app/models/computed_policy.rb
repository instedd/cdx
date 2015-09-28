class ComputedPolicy < ActiveRecord::Base

  belongs_to :user

  has_many :exceptions, class_name: "ComputedPolicyException", dependent: :destroy, inverse_of: :computed_policy

  accepts_nested_attributes_for :exceptions

  scope :delegable, -> { where(delegable: true) }
  scope :on,        -> (resource_type) { where(resource_type: resource_type) }


  def self.update_user(user)
    # TODO: Run in background
    PolicyComputer.new.update_user(user)
  end

  def self.can?(action, resource, user, opts={})
    return resource.kind_of?(Resource)\
      ? !!authorize(action, resource, user, opts)\
      : applicable_policies(action, resource, user, opts).any?
  end

  def self.can_delegate?(action, resource, user)
    can?(action, resource, user, delegable: true)
  end

  def self.authorize(action, resource, user, opts={})
    scope = self.authorize_scope(action, resource, user, opts)
    return resource.kind_of?(Resource) ? scope.first : scope
  end

  def self.authorize_scope(action, resource, user, opts={})
    policies = applicable_policies(action, resource, user, opts).includes(:exceptions)
    return resource.none if policies.empty?

    filter = policies.map(&:arel_filter).inject do |filters, filter|
      (filters && filter) ? filters.or(filter) : (filters or filter)
    end

    resource.filter(filter)
  end

  def self.applicable_policies(action, resource_or_string, user, opts={})
    resource_attributes = resource_attributes_for(resource_or_string)

    query = self.where(user_id: user.id)
      .where("resource_type = ? OR resource_type IS NULL", resource_attributes[:resource_type])

    query = query.where(delegable: opts[:delegable]) if opts.has_key?(:delegable)
    query = query.where("action = ? OR action IS NULL", action) if action && action != '*'
    query = query.where("resource_id = ? OR resource_id IS NULL", resource_attributes[:id]) if resource_attributes[:id]

    query = query.where("condition_laboratory_id = ?  OR condition_laboratory_id IS NULL",  resource_attributes[:laboratory_id])  if resource_attributes[:laboratory_id]
    query = query.where("condition_institution_id = ? OR condition_institution_id IS NULL", resource_attributes[:institution_id]) if resource_attributes[:institution_id]

    return query
  end

  def self.resource_attributes_for(resource_or_string)
    if resource_or_string == "*"
      Hash.new
    elsif resource_or_string.kind_of?(String)
      resource_klass, match, query = Resource.resolve(resource_or_string)
      (query || {}).merge(resource_type: resource_klass.resource_type, id: match)
    else
      resource = resource_or_string
      { resource_type: resource.resource_type,
        id: (resource.id if resource.respond_to?(:id)),
        laboratory_id: (resource.laboratory_id if resource.respond_to?(:laboratory_id)),
        institution_id: (resource.institution_id if resource.respond_to?(:institution_id)) }
    end
  end


  module ComputedPolicyMethods

    def resource_class
      Resource.resolve(self.resource_type)[0]
    end

    def arel_filter
      table = resource_class.arel_table
      filters = []
      filters << table[:id].eq(self.resource_id) if self.resource_id
      filters << table[:institution_id].eq(self.condition_institution_id) if self.condition_institution_id
      filters << table[:laboratory_id].eq(self.condition_laboratory_id) if self.condition_laboratory_id

      filters += exceptions.map(&:arel_filter).compact.map(&:not) if respond_to?(:exceptions)

      return filters.compact.inject{|agg, filter| agg.and(filter)}
    end

    def attributes_equal?(p2)
      self.delegable == p2.delegable && self.computed_attributes == p2.computed_attributes
    end

    def computed_attributes
      attrs = {
        action: self.action,
        resource_type: self.resource_type,
        resource_id: self.resource_id,
        condition_laboratory_id: self.condition_laboratory_id,
        condition_institution_id: self.condition_institution_id
      }
      attrs[:exceptions_attributes] = self.exceptions.map(&:computed_attributes) if self.respond_to?(:exceptions)
      return attrs
    end

    def contains(p2)
      return (self.action.nil? || self.action == p2.action)\
        && (self.resource_type.nil? || self.resource_type == p2.resource_type)\
        && (self.resource_id.nil? || self.resource_id == p2.resource_id)\
        && (self.conditions.keys.all? {|c| self.conditions[c].nil? || self.conditions[c] == p2.conditions[c] })\
        && (self.delegable || !p2.delegable)
    end

    def conditions
      return {
        laboratory_id: condition_laboratory_id,
        institution_id: condition_institution_id
      }
    end

  end

  include ComputedPolicyMethods


  class PolicyComputer

    def update_user(user)
      computed_policies = user.reload.policies.map{|p| compute_for(p)}.flatten
      computed_policies = compact_policies(computed_policies)
      existing_policies = user.computed_policies

      to_create = computed_policies.substract(existing_policies) { |p1, p2| p1.attributes_equal?(p2) }
      to_delete = existing_policies.substract(computed_policies) { |p1, p2| p1.attributes_equal?(p2) }

      # Exit if there are no changes required to avoid infinite loops
      return if to_create.empty? && to_delete.empty?

      ComputedPolicy.transaction do
        to_delete.each(&:destroy!)
        to_create.each(&:save!)
      end

      # Recursively update grantees
      Policy.where(granter_id: user.id).distinct.pluck(:user_id).each do |user_id|
        update_user(User.find(user_id))
      end
    end

    def compute_for(policy)
      policy.definition['statement'].map do |s|
        computed = compute_statement(s, policy)
      end.flatten
    end

    def compute_statement(statement, policy)
      actions = Array(statement['action'])
      resources = Array(statement['resource'])
      exceptions = Array(statement['except']).map{|ex| computed_policy_attributes_from(ex)}

      granted_statements = actions.product(resources).map do |action, resource|
        entry = computed_policy_attributes_from(resource, action)
        next if action_unrelated_to_resource?(entry[:action], entry[:resource_type])
        applicable_exceptions = exceptions.reject{ |exception| intersect_attributes(entry, exception).nil? }
        entry.merge(exceptions_attributes: applicable_exceptions)
      end.compact

      granted_statements = if policy.granter.nil?
        granted_statements
      else
        granter_statements = policy.granter.computed_policies.delegable.map(&:computed_attributes)
        intersect(granted_statements, granter_statements)
      end

      granted_statements.map do |g|
        ComputedPolicy.new(g.merge(user_id: policy.user_id, delegable: policy.delegable))
      end
    end

    def computed_policy_attributes_from(resource, action=nil)
      resource_type, resource_id, filters = resolve_resource(resource)
      return {
        action: action == '*' ? nil : action,
        resource_type: resource_type,
        resource_id: resource_id.try(:to_i),
        condition_institution_id: filters["institution"].try(:to_i),
        condition_laboratory_id: filters["laboratory"].try(:to_i)
      }
    end

    def action_unrelated_to_resource?(action, resource_type_string)
      return action.presence && (action != '*') &&\
        !action.starts_with?(resource_type_string) &&\
        !action.starts_with?("test")
    end

    def resolve_resource(resource_string)
      return [nil, nil, {}] if resource_string == '*'

      resource_klass, match, query = Resource.resolve(resource_string)
      [resource_klass.resource_type, match, query]
    end

    def intersect(granted, granter)
      granted.product(granter).map do |p1, p2|
        intersect_attributes(p1, p2)
      end.compact
    end

    def intersect_attributes(p1, p2)
      catch(:empty_intersection) do
        intersection = Hash.new
        [:resource_id, :resource_type, :action, :condition_institution_id, :condition_laboratory_id].each do |key|
          intersection[key] = intersect_attribute(p1[key], p2[key])
        end
        intersection[:exceptions_attributes] = ((p1[:exceptions_attributes] || []) | (p2[:exceptions_attributes] || []))
        return intersection
      end
    end

    def intersect_attribute(attr1, attr2)
      if attr1.nil? || attr2.nil?
        attr1 || attr2
      elsif attr1 == attr2
        attr1
      else
        throw(:empty_intersection)
      end
    end

    def compact_policies(computed_policies)
      computed_policies.delete_if do |policy|
        computed_policies.any?{|p| !p.equal?(policy) && p.contains(policy) }
      end
    end

  end

end
