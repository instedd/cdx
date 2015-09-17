class ComputedPolicy < ActiveRecord::Base

  belongs_to :user

  def self.update_user(user)
    # Run in background
    PolicyComputer.new.update_user(user)
  end

  def &(p2)
    catch(:empty_intersection) do
      resource_id = intersect_attribute(self.resource_id, p2.resource_id)
      resource_type = intersect_attribute(self.resource_type, p2.resource_type)
      action = intersect_attribute(self.action, p2.action)

      return ComputedPolicy.new action: action, resource_id: resource_id,
        resource_type: self.resource_type, user_id: self.user_id, allow: allow
    end
  end

  def contains(p2)
    return (self.action.nil? || self.action == p2.action)\
      && (self.resource_type.nil? || self.resource_type == p2.resource_type)\
      && (self.resource_id.nil? || self.resource_id == p2.resource_id)\
      && (self.allow == p2.allow)
  end

  def equal_permissions(p2)
    return self.action == p2.action\
      && self.resource_id == p2.resource_id\
      && self.resource_type == p2.resource_type\
      && self.allow == p2.allow
  end

  private

  def intersect_attribute(attr1, attr2)
    if attr1.nil? || attr2.nil?
      attr1 || attr2
    elsif attr1 == attr2
      attr1
    else
      throw(:empty_intersection)
    end
  end


  class PolicyComputer

    def update_user(user)
      computed_policies = user.policies.map{|p| compute_for(p)}.flatten
      computed_policies = compact_policies(computed_policies)

      existing_policies = user.computed_policies

      to_create = computed_policies - existing_policies
      to_drop   = existing_policies - computed_policies

      return if to_create.empty? && to_drop.empty?

      ComputedPolicy.transaction do
        to_drop.each(&:delete)
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
      granted = Array(statement['action']).product(Array(statement['resource'])).map do |action, resource|
        resource_type, resource_id = resolve_resource(resource)
        action = nil if action == '*'

        ComputedPolicy.new\
          action: action,
          resource_type: resource_type,
          resource_id: resource_id,
          allow: is_allow(statement['effect']),
          user: policy.user
      end

      return granted if policy.granter.nil?
      intersect(granted, policy.granter.computed_policies)
    end

    def is_allow(effect)
      effect.downcase == 'allow'
    end

    def resolve_resource(resource_string)
      return nil if resource_string == '*'
      resource_klass = Policy.resources.find{|r| resource_string =~ r.resource_matcher} or raise "Resource not found"
      match, query = $1, $2
      # TODO: Process query
      [resource_klass.name, match == "*" ? nil : match]
    end

    def intersect(granted, granter)
      granted.product(granter).map do |p1, p2|
        p1 & p2
      end.compact
    end

    def compact_policies(computed_policies)
      computed_policies.delete_if do |policy|
        computed_policies.any?{|p| !p.equal?(policy) && p.contains(policy) }
      end
    end

  end

end
