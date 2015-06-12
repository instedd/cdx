class Cdx::Api::Elasticsearch::Config
  def api_fields=(api_fields)
    @api_fields = api_fields
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
  attr_accessor :template_name_pattern
  attr_accessor :log
  attr_accessor :elasticsearch_url

  def searchable_fields
    @searchable_fields ||= Cdx.core_fields.select(&:searchable?).map do |core_field|
      Cdx::Api::Elasticsearch::IndexedField.for(core_field, api_fields, document_format)
    end
  end

  def document_format=(document_format)
    @document_format = document_format
  end

  def document_format
    @document_format ||= CDPDocumentFormat.new
  end
end
