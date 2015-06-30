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

  class DurationField < self
    def elasticsearch_mapping
      {
        "type" => "nested",
        "properties" => {
          "in_millis" => {
            "type" => "long",
            "index" => "not_analyzed"
          },
          "milliseconds" => {
            "type" => "integer",
            "index" => "not_analyzed"
          },
          "seconds" => {
            "type" => "integer",
            "index" => "not_analyzed"
          },
          "minutes" => {
            "type" => "integer",
            "index" => "not_analyzed"
          },
          "hours" => {
            "type" => "integer",
            "index" => "not_analyzed"
          },
          "days" => {
            "type" => "integer",
            "index" => "not_analyzed"
          },
          "months" => {
            "type" => "integer",
            "index" => "not_analyzed"
          },
          "years" => {
            "type" => "integer",
            "index" => "not_analyzed"
          }
        }
      }
    end

    def self.parse_string value
      components = value.to_s.scan /\d+\D+/
      components.inject({}) { |parsed, component| parsed.merge(parse_single_value component) }
    end

    def self.parse_single_value value
      case value.to_s
      when /^(\d+)yo?$/
        { years: $1.to_i }
      when /^(\d+)mo$/
        { months: $1.to_i }
      when /^(\d+)d$/
        { days: $1.to_i }
      when /^(\d+)hs?$/
        { hours: $1.to_i }
      when /^(\d+)m$/
        { minutes: $1.to_i }
      when /^(\d+)ms$/
        { milliseconds: $1.to_i }
      when /^(\d+)s$/
        { seconds: $1.to_i }
      when /^(\d+)$/
        { default_unit => $1.to_i }
      else
        raise "Unrecognized duration: #{value.to_s}"
      end
    end

    def self.convert_time duration
      time = 0
      duration.each { |unit, amount| time += convert_from_unit(amount, unit) }
      time
    end

    UNIT_TO_MILLISECONDS = {
      years: 31536000000,
      months: 2592000000,
      days: 86400000,
      hours: 3600000,
      minutes: 60000,
      seconds: 1000,
      milliseconds: 1
    }

    def self.convert_from_unit amount, unit
      amount * UNIT_TO_MILLISECONDS[unit.to_sym]
    end
  end
end
