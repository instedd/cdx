class Cdx::Field

  def elasticsearch_mapping
    case type
    when "nested"
      {
        "type" => "nested",
        "properties" => elasticsearch_mapping_for(sub_fields)
      }
    when "multi_field"
      {
        fields: {
          "analyzed" => {type: :string, index: :analyzed},
          name => {type: :string, index: :not_analyzed}
        }
      }
    when "enum"
      {
        "type" => "string",
        "index" => "not_analyzed"
      }
    when "dynamic"
      { "properties" => {} }
    else
      {
        "type" => type,
        "index" => "not_analyzed"
      }
    end
  end

  def elasticsearch_mapping_for fields
    Hash[fields.select(&:has_searchables?).map { |field| [field.name, field.elasticsearch_mapping] }].with_indifferent_access
  end

  def custom_fields_mapping
    {
      custom_fields: {
        type: 'object'
      }
    }
  end
end
