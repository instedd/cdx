class Cdx::Api::Elasticsearch::Config
  attr_accessor :index_name_pattern
  attr_accessor :template_name_pattern
  attr_accessor :log
  attr_accessor :elasticsearch_url
end

class Cdx::Fields
  def api_fields
    @api_fields ||= YAML.load_file(File.expand_path("../../../../../config/cdx_api_fields.yml", __FILE__))[@entity_name]
  end

  def searchable_fields
    @searchable_fields ||= first_level_core_fields.select(&:searchable?).map do |core_field|
      Cdx::Api::Elasticsearch::IndexedField.for(core_field, api_fields, document_format)
    end
  end

  def document_format=(document_format)
    @document_format = document_format
  end

  def document_format
    @document_format ||= Cdx::Api::Elasticsearch::CdxDocumentFormat[@entity_name]
  end

  def default_sort
    document_format.default_sort
  end

  def translate_entities(response)
    format = document_format
    response.map { |entity| format.translate_entity(entity) }
  end
end
