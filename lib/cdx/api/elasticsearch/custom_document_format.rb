class Cdx::Api::Elasticsearch::CustomDocumentFormat

  attr_reader :mappings

  def initialize(mappings)
    @mappings = mappings.with_indifferent_access
    @reverse_mappings = @mappings.invert.with_indifferent_access
    @default_sort = @mappings["created_at"] || "created_at"
  end

  def default_sort
    @default_sort
  end

  def indexed_field_name(cdp_field_name)
    @mappings[cdp_field_name] || cdp_field_name
  end

  # receives an test in the format used in ES and
  # translates it into a CDP compliant response
  def translate_test(test)
    Hash[test.map { |indexed_name, value|
      [cdp_field_name(indexed_name), value]
    }]
  end

  private

  def cdp_field_name(indexed_name)
    @reverse_mappings[indexed_name] || indexed_name
  end

end
