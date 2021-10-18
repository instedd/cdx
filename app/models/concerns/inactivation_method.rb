module InactivationMethod
  extend ActiveSupport::Concern

  included do
    validates_inclusion_of :inactivation_method,
                           in: -> (x) { inactivation_methods },
                           message: "is not within valid options"

  end

  class_methods do
    def inactivation_methods
      @inactivation_methods ||= entity_fields.detect { |f| f.name == 'inactivation_method' }.options
    end
  end
end