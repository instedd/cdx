module SpecimenRole
  extend ActiveSupport::Concern

  included do
    validates_inclusion_of :specimen_role,
                           in: -> (x) { specimen_role_ids },
                           allow_blank: true,
                           message: "is not within valid options"

  end

  class_methods do
    def specimen_role_ids
      @specimen_role_ids ||= entity_fields.detect { |f| f.name == 'specimen_role' }.options
    end

    def specimen_role_descriptions
      YAML.load_file(File.join("app", "models", "config", "specimen_roles.yml"))["specimen_roles"]
    end

    def specimen_roles
      @specimen_roles ||= specimen_role_ids.map do |id|
        { id: id, description: "#{id.upcase} - #{specimen_role_descriptions[id]}" }
      end
    end
  end
end