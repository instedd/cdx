class TestsSchema

  CONTEXT_KEYS = %w(condition assay_name status test_type).freeze

  def initialize locale="en-US", context=nil, manifest_or_manifests=nil
    @context = (context || {}).select{|key| CONTEXT_KEYS.include?(key.to_s)}.stringify_keys
    @locale = locale
    @manifests = Array.wrap(manifest_or_manifests || manifests_for(@context))
    raise ActiveRecord::RecordNotFound.new("No manifests found for context #{@context}") if @manifests.blank?
  end

  def self.for locale, context=nil
    TestsSchema.new(locale || "en-US", context, nil)
  end

  def manifests_for(context)
    Manifest.valid.select do |manifest|
      context.keys.all? { |field| manifest_applies_to?(manifest, field, context[field]) }
    end + [Manifest.default]
  end

  def manifest_applies_to?(manifest, field_name, value)
    field = manifest.flat_mappings.find{|mapping| field_name(mapping) == field_name}
    return field && field['options'] && field['options'].include?(value)
  end

  def build
    @schema ||= schema
  end

  private

  def schema
    schema = Hash.new

    schema["$schema"] = 'http://json-schema.org/draft-04/schema#'
    schema["type"] = "object"
    schema["title"] = schema_title
    schema["properties"] = Hash.new

    @manifests.each do |manifest|
      manifest.flat_mappings.each do |field|
        schemas_for(field).each do |name, field_schema|
          next if @context.keys.include?(name)
          if existing = schema["properties"][name]
            if existing['type'] != field_schema['type']
              Rails.logger.warn("Warning merging field #{name} from manifests #{@manifests.map(&:id)}: inconsistent types found (#{existing['type']} vs #{field_schema['type']}). Skipping field of type #{field_schema['type']} from manifest #{manifest.id}.")
            elsif existing['enum'] && field_schema['enum']
              merge_options!(existing, field_schema)
            end
          else
            schema["properties"][name] = field_schema
          end
        end
      end
    end

    ["institution_name", "laboratory_name", "device_name"].each do |field|
      name, field_schema = schemas_for("target_field" => field).first
      schema["properties"][name] = field_schema
    end

    schema
  end

  def merge_options!(existing, newfield)
    existing['enum'] |= newfield['enum']
    existing['values'].merge!(newfield['values'] || {}) if existing['values']
  end

  def schema_title
    (@context.values + [@locale]).map(&:to_s).join('.') rescue @locale
  end

  def schemas_for field
    schema = Hash.new
    name = field_name(field)

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
      set_searchable schema, field
      coords_schema(coords = Hash.new, field)
      return [[name, schema], ["#{name}_coords", coords]]
    else
      string_schema schema
    end

    set_searchable schema, field
    [[name, schema]]
  end

  def set_searchable schema, field
    schema['searchable'] = field["core"] && field["indexed"] || false
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

  def string_schema schema
    schema["type"] = "string"
  end

  def location_schema schema
    schema["type"] = "string"
    schema["location-service"] = {
      "url" => Settings.location_service_url,
      "set" => Settings.location_service_set
    }
  end

  def coords_schema schema, field
    schema["title"] = "#{field_title(field)} coordinates"
    schema["searchable"] = false
    schema["type"] = "string"
    schema["format"] = "lat,lng"
    schema["location_identifier"] = field_name(field)
  end

end
