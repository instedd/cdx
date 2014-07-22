module Cdx::Api::Elasticsearch::Concerns::EventFieldDefinition
  extend ActiveSupport::Concern

  included do
    def self.sensitive_fields
      @sensitive_fields ||= event_fields_config[:sensitive_fields]
    end

    def self.searchable_fields
      @searchable_fields ||= event_fields_config[:searchable_fields].map do |definition|
        Cdx::Api::Elasticsearch::IndexedField.from definition
      end
    end

    def self.event_fields_config
      config_filename = "#{Rails.root}/config/cdx_api_fields.yml"
      unless File.exists?(config_filename)
        config_filename = File.expand_path("../../../../../../config/cdx_api_fields.yml", __FILE__)
      end

      YAML.load_file(config_filename).with_indifferent_access
    end
  end
end
