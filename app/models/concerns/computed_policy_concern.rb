module ComputedPolicyConcern

  extend ActiveSupport::Concern

  included do

    def resource_class
      Resource.resolve(self.resource_type)[0]
    end

    def arel_filter
      table = resource_class.arel_table
      filters = []
      filters << table[:id].eq(self.resource_id) if self.resource_id
      filters << table[:institution_id].eq(self.condition_institution_id) if self.condition_institution_id
      filters << table[:laboratory_id].eq(self.condition_laboratory_id)   if self.condition_laboratory_id

      filters += exceptions.map(&:arel_filter).compact.map(&:not) if respond_to?(:exceptions)

      return filters.compact.inject{|agg, filter| agg.and(filter)}
    end

    def applies_to?(resource_or_string, action, opts={})
      resource_attributes = ComputedPolicy.resource_attributes_for(resource_or_string)

      return (self.resource_id.nil? || self.resource_id == resource_attributes[:id])\
        && (self.resource_type.nil? || self.resource_type == resource_attributes[:resource_type])\
        && (self.action.nil? || self.action == resource_attributes[:action])\
        && (self.condition_institution_id.nil? || self.condition_institution_id == resource_attributes[:institution_id])\
        && (self.condition_laboratory_id.nil? || self.condition_laboratory_id == resource_attributes[:laboratory_id])
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
        laboratory: condition_laboratory_id,
        institution: condition_institution_id
      }
    end

  end

end
