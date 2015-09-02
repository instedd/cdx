class Cdx::Scope
  def elasticsearch_mapping
    { "properties" => elasticsearch_mapping_for(fields).merge(custom_fields_mapping) }
  end

  def elasticsearch_mapping_for fields
    Hash[fields.select(&:searchable?).map { |field| [field.name, field.elasticsearch_mapping] }].with_indifferent_access
  end

  def custom_fields_mapping
    if allows_custom?
      {
        custom_fields: {
          type: 'object'
        }
      }
    else
      {}
    end
  end
end
