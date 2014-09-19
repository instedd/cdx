class EventsSchema
  def initialize manifest, assay_name, locale
    @assay_name = assay_name
    @locale = locale
    @manifest = manifest
  end

  def self.for assay_name, locale
    EventsSchema.new Manifest.find_by_assay_name(assay_name), assay_name, locale
  end

  def schema
    @schema ||= build_schema
  end

  private

  def build_schema
    schema = Hash.new

    schema["$schema"] = 'http://json-schema.org/draft-04/schema#'
    schema["type"] = "object"
    schema["title"] = @assay_name + "." + @locale
    schema["properties"] = Hash.new

    @manifest.field_mapping.each do |field|
      if field["core"] && field["indexed"]
        schema["properties"][field_name(field)] = schema_for field
      end
    end
    schema
  end

  def schema_for field
    schema = Hash.new
    schema["title"] = field_title field
    case field["type"]
    when "date"
      date_schema schema
    when "integer"
      integer_schema schema, field
    when "enum"
      enum_schema schema, field
    when "location"
      location_schema schema
    else
      string_schema schema
    end
    schema
  end

  def field_name field
    field["target_field"].split(Manifest::PATH_SPLIT_TOKEN).last
  end

  def field_title field
    field_name(field).titleize
  end

  def date_schema schema
    schema["type"] = "string"
    schema["format"] = "date-time"
    schema["resolution"] = "second"
  end

  def integer_schema schema, field
    schema["type"] = "integer"
    if field["valid_values"] && field["valid_values"]["range"]
      schema["minimum"] = field["valid_values"]["range"]["min"]
      schema["maximum"] = field["valid_values"]["range"]["max"]
    end
  end

  def enum_schema schema, field
    schema["type"] = "string"
    schema["enum"] = field["options"]
    values = field["options"].inject Hash.new do |values, option|

      #TODO Remove this regex and let the manifest specify this values
      kind = case option
      when /.*positive.*/i
        'positive'
      when /.*negative.*/i
        'negative'
      end

      values[option] = { "name" => option.titleize, "kind" => kind }
      values
    end
    schema["values"] = values
  end

  def string_schema schema
    schema["type"] = "string"
  end

  def location_schema schema
    schema["type"] = "string"
    schema["enum"] = Array.new
    schema["locations"] = Location.all.inject(Hash.new) do |locations, location|
      schema["enum"].push(location.id.to_s)
      locations[location.id.to_s] = {
        "name" => location.name,
        "level" => location.admin_level,
        "parent" => location.parent_id
      }
      locations
    end
  end
end
