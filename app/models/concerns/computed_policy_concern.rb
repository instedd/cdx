module ComputedPolicyConcern

  extend ActiveSupport::Concern

  included do

    def resource_class
      Resource.resolve(self.resource_type)[0]
    end

    def arel_filter
      table = resource_class.arel_table
      filters = []

      if self.resource_id
        if resource_class == Site
          filters << table[:prefix].matches("#{self.resource_id}%")
        else
          filters << table[:id].eq(self.resource_id)
        end
      end

      conditions.each do |key, value|
        if key == :site
          filters << table["#{key}_prefix".to_sym].matches("#{value}%") if value
        else
          filters << table["#{key}_id".to_sym].eq(value) if value
        end
      end

      filters += exceptions.map(&:arel_filter).compact.map(&:not) if respond_to?(:exceptions)

      return filters.compact.inject{|agg, filter| agg.and(filter)}
    end

    def arel_condition_filter
      filters = conditions.map do |key, value|
        if key == :site
          condition_class(key).arel_table[:prefix].matches("#{value}#{'%' if include_subsites}") if value
        else
          condition_class(key).arel_table[:id].eq(value) if value
        end
      end

      if respond_to?(:exceptions)
        filters += exceptions.map(&:arel_condition_filter).compact.map(&:not)
      end

      return filters.compact.inject{|agg, filter| agg.and(filter)}
    end

    def applies_to?(resource_or_string, action, opts={})
      resource_attributes = ComputedPolicy.resource_attributes_for(resource_or_string)

      return (self.resource_id.nil? || self.resource_id.to_s == resource_attributes[:id].to_s)\
        && (self.resource_type.nil? || self.resource_type == resource_attributes[:resource_type])\
        && (self.action.nil? || self.action == resource_attributes[:action])\
        && (self.conditions.all? {|key, value| value.nil? || value.to_s == resource_attributes["#{key}_id".to_sym].to_s})
    end

    def attributes_equal?(p2)
      self.delegable == p2.delegable && self.computed_attributes == p2.computed_attributes
    end

    def computed_attributes
      attrs = {
        action: self.action,
        resource_type: self.resource_type,
        resource_id: self.resource_id,
        include_subsites: self.include_subsites
      }

      conditions.each do |key, value|
        attrs["condition_#{key}_id".to_sym] = value
      end

      if self.respond_to?(:exceptions)
        attrs[:exceptions_attributes] = self.exceptions.map(&:computed_attributes)
      end

      return attrs
    end

    def contains(p2)
      return (self.action.nil? || self.action == p2.action)\
        && (self.resource_type.nil? || self.resource_type == p2.resource_type)\
        && (self.resource_id.nil? || self.resource_id == p2.resource_id)\
        && (self.conditions.keys.all? {|c| self.conditions[c].nil? || self.conditions[c] == p2.conditions[c] })\
        && (self.delegable || !p2.delegable)\
        && (!self.respond_to?(:exceptions) || self.exceptions.blank?)
    end

    def conditions
      ComputedPolicy::CONDITIONS.map do |key|
        [key, send("condition_#{key}_id")]
      end.to_h
    end

    def condition_class(key)
      key.to_s.classify.constantize
    end

  end

end
