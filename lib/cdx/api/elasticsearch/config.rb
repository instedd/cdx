module Cdx::Api::Elasticsearch::Config
  class << self
    def api_fields=(api_fields)
      @api_fields = api_fields.with_indifferent_access
    end

    def api_fields
      unless @api_fields
        self.api_fields = YAML.load_file(File.expand_path("../../../../../config/cdx_api_fields.yml", __FILE__))
      end
      @api_fields
    end

    def api_fields_filename(api_fields_filename)
      self.api_fields = YAML.load_file(api_fields_filename)
    end

    attr_accessor :index_name_pattern
    attr_accessor :log

    def sensitive_fields
      @sensitive_fields ||= api_fields[:sensitive_fields]
    end

    def searchable_fields
      @searchable_fields ||= api_fields[:searchable_fields].map do |definition|
        Cdx::Api::Elasticsearch::IndexedField.from definition
      end
    end
  end
end
