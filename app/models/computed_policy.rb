class ComputedPolicy < ApplicationRecord

  belongs_to :user

  has_many :exceptions, class_name: "ComputedPolicyException", dependent: :destroy, inverse_of: :computed_policy

  accepts_nested_attributes_for :exceptions

  def exceptions_attributes=(values)
    super(values.map {|value| value.except(:include_subsites)})
  end

  scope :delegable, -> { where(delegable: true) }
  scope :on,        -> (resource_type) { where(resource_type: resource_type) }

  include ComputedPolicyConcern

  CONDITIONS = [:institution, :site, :device].freeze

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
    return resource.kind_of?(Resource) || resource.kind_of?(Hash)\
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
      (filters && filter) ? filters.or(filter) : nil
    end

    resource.filter(filter)
  end

  def self.applicable_policies(action, resource_or_string, user=nil, opts={})
    resource_attributes = resource_attributes_for(resource_or_string)

    query = self.where("resource_type = ? OR resource_type IS NULL", resource_attributes[:resource_type])
    query = query.where(user_id: user.id) if user

    query = query.where(delegable: opts[:delegable]) if opts.has_key?(:delegable)
    query = query.where("action = ? OR action IS NULL", action) if action && action != '*'
    query = query.where("resource_id = ? OR resource_id IS NULL", resource_attributes[:id]) if resource_attributes[:id]
    query = query.where("(? = resource_id) OR (include_subsites AND ? LIKE concat(resource_id, '%')) OR resource_id IS NULL", "#{resource_attributes[:prefix]}", "#{resource_attributes[:prefix]}") if resource_attributes[:prefix]

    CONDITIONS.each do |condition|
      if (value = resource_attributes["#{condition}_id".to_sym])
        if condition == :site
          # For site we need to do a prefix query

          query = query.where("(include_subsites AND ? LIKE concat('%', condition_#{condition}_id, '%')) OR (? = condition_#{condition}_id) OR condition_#{condition}_id IS NULL", value.to_s, value.to_s)
        else
          query = query.where("condition_#{condition}_id = ? OR condition_#{condition}_id IS NULL", value)
        end
      elsif resource_attributes.has_key?("#{condition}_id".to_sym)
        query = query.where("condition_#{condition}_id IS NULL")
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

      if resource.is_a?(Site)
        attrs[:prefix] = resource.prefix
      elsif resource.respond_to?(:id)
        attrs[:id] = resource.id
      end

      CONDITIONS.each do |condition|
        key = "#{condition}_id".to_sym
        if resource.respond_to?(key)
          value = resource.send(key)
          if condition == :site && value
            # We need to get the site's prefix
            value = Site.prefix(value)
          end
          attrs[key] = value
        end
      end
      attrs
    end
  end

  def self.condition_resources_for(action, resource, user)
    policies = self.applicable_policies(action, resource, user).where(resource_id: nil).includes(:exceptions)

    return {
      institution: Institution.none,
      site: Site.none,
      device: Device.none
    } if policies.empty?

    institution_table, site_table, device_table = [Institution, Site, Device].map(&:arel_table)

    select = [institution_table[:id], site_table[:id], device_table[:id]]
    from = institution_table
            .join(site_table, Arel::Nodes::OuterJoin)
            .on(institution_table[:id].eq(site_table[:institution_id]))
            .join(device_table, Arel::Nodes::OuterJoin)
            .on(site_table[:id].eq(device_table[:site_id]))
            .source

    filters = policies.map(&:arel_condition_filter).inject do |filters, filter|
      (filters && filter) ? filters.or(filter) : nil
    end

    arel_query = institution_table.project(*select).from(from)
    arel_query = arel_query.where(filters) if filters

    devices_without_sites_query = institution_table
                      .project(*[institution_table[:id], Arel.sql('NULL'), device_table[:id]])
                      .join(device_table)
                      .on(institution_table[:id].eq(device_table[:institution_id]))
                      .join(site_table, Arel::Nodes::OuterJoin)
                      .on('1 = 0')
                      .where(device_table[:site_id].eq(nil))

    devices_without_sites_query = devices_without_sites_query.where(filters) if filters

    result = self.connection.execute("#{arel_query.to_sql} UNION #{devices_without_sites_query.to_sql}")
    institution_ids, site_ids, device_ids = result.to_a.transpose.map{|ids| ids.try(:uniq)}

    return {
      institution: Institution.where(id: institution_ids),
      site: Site.where(id: site_ids),
      device: Device.where(id: device_ids)
    }
  end

  def self.authorized_users(action, resource)
    self.applicable_policies(action, resource)\
      .includes(:user, :exceptions)\
      .group_by(&:user)\
      .select do |user, policies|
        policies.any? do |policy|
          not policy.exceptions.any? do |exception|
            exception.applies_to?(resource, action)
          end
        end
      end.keys
  end


  class PolicyComputer

    def update_user(user)
      computed_policies = policies_for(user).map{|p| compute_for(p)}.flatten
      computed_policies = compact_policies(computed_policies)
      existing_policies = user.computed_policies.to_a

      to_create = substract(computed_policies, existing_policies)
      to_delete = substract(existing_policies, computed_policies)

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

    def substract(policies, other_policies)
      policies.reject do |p1|
        other_policies.any? { |p2| p1.attributes_equal?(p2) }
      end
    end

    def policies_for(user)
      user.policies.reload +
        user.implicit_policies +
        user.roles.includes(:policy).flat_map(&:policy).each { |p| p.user = user }
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

      granted_statements = if policy.granter
        granter_statements = policy.granter.computed_policies.delegable.map(&:computed_attributes)
        intersect(granted_statements, granter_statements)
      elsif policy.role
        granter_statements = Policy.owner(nil, policy.role.institution.id, policy.role.institution.kind).to_computed_policies.select(&:delegable).map(&:computed_attributes)
        intersect(granted_statements, granter_statements)
      else
        granted_statements
      end

      granted_statements.map do |g|
        ComputedPolicy.new(g.merge(user_id: policy.user_id, delegable: statement.fetch('delegable', false), include_subsites: statement.fetch('includeSubsites', false)))
      end
    end

    def computed_policy_attributes_from(resource, action=nil)
      resource_type, resource_id, filters = resolve_resource(resource)

      attrs = {
        action: action == '*' ? nil : action,
        resource_type: resource_type,
        resource_id: resource_id(resource_id, resource_type)
      }

      ComputedPolicy::CONDITIONS.each do |condition|
        attrs["condition_#{condition}_id".to_sym] = condition_value(filters, condition)
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
          intersection[key] = intersect_attribute(p1, p2, key)
        end
        intersection[:exceptions_attributes] = ((p1[:exceptions_attributes] || []) | (p2[:exceptions_attributes] || []))
        intersection[:include_subsites] = p1[:include_subsites] && p2[:include_subsites]
        return intersection
      end
    end

    def intersect_attribute(policy_1, policy_2, key)
      attr1 = policy_1[key]
      attr2 = policy_2[key]

      if attr1.nil? || attr2.nil?
        return attr1 || attr2
      end

      if attr1.to_s == attr2.to_s
        return attr1
      end

      if (key == :resource_id && policy_1[:resource_type] == "site" && policy_2[:resource_type] == "site") || key == :condition_site_id
        # Special case: when interescting site prefixes the result is the longest,
        # if one is a prefix of the other.
        #   - 1.2 | 1 -> 1.2
        #   - 1.2.3 | 1.2 -> 1.2.3
        #   - 1.2 | 3.4 -> :empty_intersection
        attr1 = attr1.to_s
        attr2 = attr2.to_s

        if attr1.starts_with?(attr2) && policy_2[:include_subsites]
          return attr1
        elsif attr2.starts_with?(attr1) && policy_1[:include_subsites]
          return attr2
        end
      end

      throw(:empty_intersection)
    end

    def compact_policies(computed_policies)
      computed_policies.delete_if do |policy|
        computed_policies.any?{|p| !p.equal?(policy) && p.contains(policy) }
      end
    end

    def site_prefix(id)
      @site_id_to_prefix ||= {}
      @site_id_to_prefix[id] ||= Site.prefix(id)
    end

    def resource_id(id, type)
      id = id.try(:to_i)

      # For a Site the resource_id need to be its prefix
      if type == "site" && id
        id = site_prefix(id)
      end

      id
    end

    def condition_value(filters, condition)
      value = filters[condition.to_s].try(:to_i)

      # For a site, the condition needs to be the prefix
      if condition == :site && value
        value = site_prefix(value)
      end

      value
    end

  end

end
