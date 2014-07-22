module Cdx::Api::Elasticsearch::Concerns::EventFieldDefinition
  extend ActiveSupport::Concern

  included do
    def self.sensitive_fields
      @sensitive_fields ||= YAML.load_file('config/event_fields.yml').with_indifferent_access[:sensitive_fields]
    end

    def self.searchable_fields
      @searchable_fields ||= YAML.load_file('config/event_fields.yml').with_indifferent_access[:searchable_fields].map do |definition|
        Cdx::Api::Elasticsearch::IndexedField.from definition
      end
    end
  end
end
