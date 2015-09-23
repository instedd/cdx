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

  def self.can?(action, resource, user)
    query(action, resource, user).any?
  end

  def self.can_delegate?(action, resource, user)
    query(action, resource, user).where(delegable: true).any?
  end

  def self.authorize(action, resource, user)
    filter = query(action, resource, user).map(&:arel_filter).inject { |filters, filter| filters.or(filter) }
    resource.resource_class.where(filter)
  end

  def self.query(action, resource, user)
    query = self.where(user_id: user.id)
      .where("action = ? OR action IS NULL", action)
      .where("resource_type = ? OR resource_type IS NULL", resource.resource_type)

    query = query.where("resource_id = ? OR resource_id IS NULL", resource.id) if resource.respond_to?(:id)

    query = query.where("condition_laboratory_id = ?  OR condition_laboratory_id IS NULL",  resource.laboratory_id)  if resource.respond_to?(:laboratory_id)
    query = query.where("condition_institution_id = ? OR condition_institution_id IS NULL", resource.institution_id) if resource.respond_to?(:institution_id)

    return query
  end

  def resource_class
    Resource.resolve(self.resource_type)[0]
  end

  def arel_filter
    table = resource_class.arel_table
    filters = []
    filters << table[:id].eq(self.resource_id) if self.resource_id
    filters << table[:institution_id].eq(self.condition_institution_id) if self.condition_institution_id
    filters << table[:laboratory_id].eq(self.condition_laboratory_id) if self.condition_laboratory_id

    return filters.inject{|agg, filter| agg.and(filter)}
  end


  module ComputedPolicyAttributes

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

  include ComputedPolicyAttributes


  class PolicyComputer

    def update_user(user)
      computed_policies = user.policies(:reload).map{|p| compute_for(p)}.flatten
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
        applicable_exceptions = exceptions.reject{ |exception| intersect_attributes(entry, exception).nil? }
        entry.merge(exceptions_attributes: applicable_exceptions)
      end

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

    def resolve_resource(resource_string)
      return [nil, nil, {}] if resource_string == '*'

      resource_klass, match, query = Resource.resolve(resource_string)

      [resource_klass.resource_type,
       match == "*" ? nil : match,
       Rack::Utils.parse_nested_query(query) || Hash.new]
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
