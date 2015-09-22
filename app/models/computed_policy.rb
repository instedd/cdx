class ComputedPolicy < ActiveRecord::Base

  belongs_to :user

  has_many :exceptions, class_name: "ComputedPolicyException", dependent: :destroy, inverse_of: :computed_policy

  accepts_nested_attributes_for :exceptions

  scope :delegable,  -> { where(delegable: true) }


  def self.update_user(user)
    # TODO: Run in background
    PolicyComputer.new.update_user(user)
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


  class PolicyComputer

    def update_user(user)
      computed_policies = user.policies.map{|p| compute_for(p)}.flatten
      computed_policies = compact_policies(computed_policies)

      # TODO: Calculate difference using attributes
      existing_policies = user.computed_policies
      to_create = computed_policies - existing_policies
      to_drop   = existing_policies - computed_policies
      return if to_create.empty? && to_drop.empty?

      ComputedPolicy.transaction do
        to_drop.each(&:destroy)
        to_create.each(&:save!)
      end

      # Recursively call grantees
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
        granter_statements = policy.granter.computed_policies.delegable.map{|p| attributes_for(p)}
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

    def attributes_for(computed_policy)
      attrs = {
        action: computed_policy.action,
        resource_type: computed_policy.resource_type,
        resource_id: computed_policy.resource_id,
        condition_laboratory_id: computed_policy.condition_laboratory_id,
        condition_institution_id: computed_policy.condition_institution_id
      }
      attrs[:exceptions_attributes] = computed_policy.exceptions.map{|e| attributes_for(e)} if computed_policy.respond_to?(:exceptions)
      return attrs
    end

    def resolve_resource(resource_string)
      return [nil, nil, {}] if resource_string == '*'
      resource_klass = Policy.resources.find{|r| resource_string =~ r.resource_matcher} or raise "Resource not found"
      match, query = $1, $2

      [resource_klass.name,
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
