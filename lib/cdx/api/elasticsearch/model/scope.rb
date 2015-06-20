class Cdx::Scope
  def elasticsearch_mapping
    { "properties" => elasticsearch_mapping_for(fields).merge(custom_fields_mapping) }
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
