class ComputedPolicy < ActiveRecord::Base

  belongs_to :user

  has_many :exceptions, class_name: "ComputedPolicyException", dependent: :destroy, inverse_of: :computed_policy

  accepts_nested_attributes_for :exceptions

  scope :delegable, -> { where(delegable: true) }
  scope :on,        -> (resource_type) { where(resource_type: resource_type) }

  include ComputedPolicyConcern

  CONDITIONS = [:institution, :laboratory, :device].freeze

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
    return resource.kind_of?(Resource)\
      ? authorize_instance(action, resource, user, opts)\
      : authorize_scope(action, resource, user, opts)
  end

  def self.authorize_instance(action, resource, user, opts={})
    applicable_policies(action, resource, user, opts).includes(:exceptions).reject do |policy|
      policy.exceptions.any? do |exception|
        exception.applies_to?(resource, action, opts)
      end
    end.empty? ? nil : resource
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

    CONDITIONS.each do |condition|
      if (value = resource_attributes["#{condition}_id".to_sym])
        query = query.where("condition_#{condition}_id = ? OR condition_#{condition}_id IS NULL", value)
      end
    end

    return query
  end

  def self.resource_attributes_for(resource_or_string)
    if resource_or_string == "*"
      Hash.new
    elsif resource_or_string.kind_of?(Hash)
      resource_or_string
    elsif resource_or_string.kind_of?(String)
      resource_klass, match, query = Resource.resolve(resource_or_string)
      (query || {}).merge(resource_type: resource_klass.resource_type, id: match)
    else
      resource = resource_or_string
      attrs = { resource_type: resource.resource_type }
      attrs[:id] = resource.id if resource.respond_to?(:id)
      CONDITIONS.each do |condition|
        key = "#{condition}_id".to_sym
        attrs[key] = resource.send(key) if resource.respond_to?(key)
      end
      attrs
    end
  end

  def self.condition_resources_for(action, resource, user)
    policies = self.applicable_policies(action, resource, user).includes(:exceptions)

    return {
      institution: Institution.none,
      laboratory: Laboratory.none,
      device: Device.none
    } if policies.empty?

    institution_table, laboratory_table, device_table = [Institution, Laboratory, Device].map(&:arel_table)

    select = [institution_table[:id], laboratory_table[:id], device_table[:id]]
    from = Institution.joins(laboratories: :devices).arel.source
    filters = nil

    policies.each do |policy|
      institution_filter = institution_table[:id].eq(policy.condition_institution_id) if policy.condition_institution_id
      laboratory_filter  = laboratory_table[:id].eq(policy.condition_laboratory_id) if policy.condition_laboratory_id
      device_filter      = device_table[:id].eq(policy.condition_device_id) if policy.condition_device_id

      filter = [institution_filter, laboratory_filter, device_filter].compact
      next if filter.empty?
      and_filter = filter.inject{|conj, f| conj.and(f)}
      filters = filters ? filters.or(and_filter) : and_filter
    end

    arel_query = institution_table.project(*select).from(from).where(filters)
    result = self.connection.execute(arel_query.to_sql)
    institution_ids, laboratory_ids, device_ids = result.to_a.transpose

    # FIXME: A policy for a test result by id would yield a nil filter, effectively returning all resources

    return {
      institution: Institution.find(institution_ids.uniq),
      laboratory: Laboratory.find(laboratory_ids.uniq),
      device: Device.find(device_ids.uniq)
    }

  end


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

      # Update subscriber percolators
      user.subscribers.find_each &:create_percolator

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

      attrs = {
        action: action == '*' ? nil : action,
        resource_type: resource_type,
        resource_id: resource_id.try(:to_i)
      }

      ComputedPolicy::CONDITIONS.each do |condition|
        attrs["condition_#{condition}_id".to_sym] = filters[condition.to_s].try(:to_i)
      end

      attrs
    end

    def action_unrelated_to_resource?(action, resource_type_string)
      return action.presence && (action != '*') &&\
        !action.starts_with?(resource_type_string)
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
        conditions_attributes = ComputedPolicy::CONDITIONS.map{|condition| "condition_#{condition}_id".to_sym}
        ([:resource_id, :resource_type, :action] + conditions_attributes).each do |key|
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
