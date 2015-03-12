class EventsSchema
  def initialize locale="en-US", assay_name=nil, manifest=nil
    @assay_name = assay_name
    @locale = locale
    @manifest = manifest
  end

  def self.for locale, assay_name=nil
    locale ||= "en-US"
    if assay_name.present?
      EventsSchema.new locale, assay_name, Manifest.find_by_assay_name(assay_name)
    else
      EventsSchema.new locale
    end
  end

  def build
    @schema ||= schema
  end

  private

  def schema
    schema = Hash.new

    schema["$schema"] = 'http://json-schema.org/draft-04/schema#'
    schema["type"] = "object"
    schema["title"] = if @assay_name.present?
      "#{@assay_name}.#{@locale}"
    else
      @locale
    end
    schema["properties"] = Hash.new

    (@manifest || Manifest.default).flat_mappings.each do |field|
      schema["properties"][field_name(field)] = schema_for field
    end

    unless @manifest
      schema["properties"]["assay_name"] = all_assay_names_schema
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

    schema['searchable'] = field["core"] && field["indexed"] || false

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
    schema["enum"] = enum = []
    schema["locations"] = locations = {}

    Location.includes(:parent).find_each do |location|
      enum << location.geo_id
      locations[location.geo_id] = {
        "name" => location.name,
        "level" => location.admin_level,
        "parent" => location.parent.try(:geo_id),
        "lat" => location.lat,
        "lng" => location.lng
      }
    end
  end


  def all_assay_names_schema
    enum = all_assay_names
    values = enum.inject Hash.new do |values, assay_name|
        values[assay_name] = { "name" => assay_name.titleize }
        values
      end
    {
      "title" => "Assay Name",
      "type" => "string",
      "enum" => enum,
      "values" => values
    }

  end

  def all_assay_names
    #TODO This should be AssayName.all
    assay_names = Manifest.valid.collect do |manifest|
      assay_mapping = manifest.flat_mappings.detect do |mapping|
        mapping["target_field"] == "assay_name"
      end

      assay_mapping["options"]
    end.flatten
    assay_names.delete nil
    assay_names
  end
end
