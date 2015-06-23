class Cdx::Field

  def elasticsearch_mapping
    {
      "type" => type,
      "index" => "not_analyzed"
    }
  end

  def custom_fields_mapping
    {
      custom_fields: {
        type: 'object'
      }
    }
  end

  class NestedField < self
    def elasticsearch_mapping
      {
        "type" => "nested",
        "properties" => Hash[sub_fields.select(&:has_searchables?).map { |field|
          [field.name, field.elasticsearch_mapping]
        }]
      }
    end
  end

  class MultiField < self
    def elasticsearch_mapping
      {
        fields: {
          "analyzed" => {type: :string, index: :analyzed},
          name => {type: :string, index: :not_analyzed}
        }
      }
    end
  end

  class EnumField < self
    def elasticsearch_mapping
      {
        "type" => "string",
        "index" => "not_analyzed"
      }
    end
  end

  class DynamicField < self
    def elasticsearch_mapping
      { "properties" => {} }
    end
  end
end
