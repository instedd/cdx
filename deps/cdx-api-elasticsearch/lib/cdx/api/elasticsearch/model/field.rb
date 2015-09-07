class Cdx::Field
  def before_index(fields)
    # Nothing
  end

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
        "properties" => Hash[sub_fields.select(&:searchable?).map { |field|
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

    def self.parse_range value
      lower_bound, upper_bound = value.split "..", 2
      range = {}
      range["from"] = Cdx::Field::DurationField.string_to_time(lower_bound) unless lower_bound.empty?
      range["to"] = Cdx::Field::DurationField.string_to_time(upper_bound) unless upper_bound.empty?
      range
    end

    def self.string_to_time value
      convert_time parse_string(value)
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

    def self.millis(value, unit)
      UNIT_TO_MILLISECONDS[unit] * value
    end

    def self.years(value)
      {"years" => value, "in_millis" => millis(value, :years)}
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

    def before_index(fields)
      scoped_field = fields[scope.name]
      return unless scoped_field

      field = scoped_field[name]
      return unless field

      millis = 0
      UNIT_TO_MILLISECONDS.each do |unit, multiplier|
        field_value = field[unit.to_s]
        if field_value
          millis += field_value.to_i * multiplier
        end
      end
      field["in_millis"] = millis
    end

    def self.convert_from_unit amount, unit
      amount * UNIT_TO_MILLISECONDS[unit.to_sym]
    end
  end
end
