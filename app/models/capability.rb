class Capability

  def initialize field_mapping, assay_name, locale
    @schema = {}
    add_header(assay_name, locale)
    field_mapping.each do |f|
      if f["core"] && f["indexed"]
        add_field_to_schema f
      end
    end
  end

  def to_json
    @schema
  end

  private

  def add_header assay_name, locale
    @schema["$schema"] = 'http://json-schema.org/draft-04/schema#'
    @schema["type"] = "object"
    @schema["title"] = assay_name + "." + locale
    @schema["properties"] = {}
  end

  def add_field_to_schema field
    name = (field["target_field"].split Manifest::PATH_SPLIT_TOKEN).last
    @schema["properties"][name] = to_schema field
  end

  def to_schema field
    json = {}
    json["title"] = field_title field["target_field"]
    type = field["type"]
    if type == "date"
      date_schema json, field
    elsif type == "integer"
      integer_schema json, field
    elsif type == "location"
      location_schema json
    else
      string_schema json, field
    end
  end

  def field_title name
    title = name.split(Manifest::COLLECTION_SPLIT_TOKEN).last
    title = title.gsub('_',' ')
    title = title.capitalize
  end

  def date_schema json, field
    json["type"] = "string"
    json["format"] = "date-time"
    json["resolution"] = "day"
    json
  end

  def integer_schema json, field
    json["type"] = "number"
    if field["valid_values"] && field["valid_values"]["range"]
      json["minimum"] = field["valid_values"]["range"]["min"]
      json["maximum"] = field["valid_values"]["range"]["max"]
    end
    json
  end

  def string_schema json, field
    json["type"] = "string"
    if field["valid_values"] && field["valid_values"]["options"]
      json["enum"] = field["valid_values"]["options"]
    end
    json
  end

  def location_schema json
    locations = Location.all
    json["type"] = "string"
    json["enum"] = []
    props_and_vals = ["name", "level", "parent"].zip [:name, :depth, :parent_id]
    json["locations"] = locations.inject({}) do |values, location|
      json["enum"].push(location.id.to_s)
      value = {}
      props_and_vals.each do |pv|
        value[pv.first] = location[pv.second]
      end
      values[location.id.to_s] = value
      values
    end
    json
  end

end
