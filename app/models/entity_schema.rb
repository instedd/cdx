class EntitySchema
  def initialize(locale)
    @locale = locale || "en-US"
  end

  def build
    @schema ||= schema
  end

  def scopes
    subclass_responsibility
  end

  private

  def schema
    schema = Hash.new

    schema["$schema"] = 'http://json-schema.org/draft-04/schema#'
    schema["type"] = "object"
    schema["title"] = schema_title
    schema["properties"] = Hash.new

    scopes.each do |scope|
      scope_properties = {}

      scope.fields.each do |field|
        scope_properties[field.name] = schemas_for(field)
      end

      schema['properties'][scope.name] = {
        "type" => "object",
        "title" => field_title(scope),
        "properties" => scope_properties
      }
    end

    # TODO dehardcode location service in location scope
    set_location_service schema

    schema
  end

  def schema_title
    @locale
  end

  def schemas_for field
    schema = Hash.new
    schema["title"] = field_title field

    if field.name == "condition"
      condition_schema schema
    else
      case field.type
      when "date"
        date_schema schema
      when "integer"
        integer_schema schema, field
      when "enum"
        enum_schema schema, field
      when 'nested'
        nested_schema schema, field
      when 'duration'
        duration_schema schema, field
      else
        string_schema schema
      end
    end

    schema['searchable'] = field.searchable? || false

    schema
  end

  def field_title field
    field.name.titleize
  end

  def date_schema schema
    schema["type"] = "string"
    schema["format"] = "date-time"
    schema["resolution"] = "second"
  end

  def duration_schema schema, field
    schema["type"] = "object"
    schema["class"] = "duration"
    schema["properties"] = {}
    %w[milliseconds seconds minutes hours days months years].each do |period|
      schema["properties"][period] = {
        "type" => "integer",
        "title" => "#{field_title field} #{period}"
      }
    end
  end

  def integer_schema schema, field
    schema["type"] = "integer"
    if field.valid_values.present? && field.valid_values["range"].present?
      schema["minimum"] = field.valid_values["range"]["min"]
      schema["maximum"] = field.valid_values["range"]["max"]
    end
  end

  def enum_schema schema, field
    schema["type"] = "string"

    if field.options.present?
      schema["enum"] = field.options

      values = field.options.inject Hash.new do |values, option|
        #TODO Remove this regex and let the manifest specify this values
        kind = case option
        when /.*pos.*/i
          'positive'
        when /.*neg.*/i
          'negative'
        end

        values[option] = { "name" => option.titleize }
        values[option]['kind'] = kind if kind
        values
      end

      schema["values"] = values
    end
  end

  def condition_schema schema
    schema["type"] = "string"
    schema["enum"] = Condition.order(:name).pluck(:name)
  end

  def nested_schema schema, field
    schema['type'] = 'array'
    schema['items'] = {}
    schema['items']['type'] = 'object'
    schema['items']['properties'] = {}
    field.sub_fields.each do |field|
       schema['items']['properties'][field.name] = schemas_for field
    end
  end

  def string_schema schema
    schema["type"] = "string"
  end

  def set_location_service schema
    if schema['properties']['location'].present?
      schema['properties']['location']['location-service'] = {
        'url' => Settings.location_service_url,
        'set' => Settings.location_service_set
      }
    end
  end
end
