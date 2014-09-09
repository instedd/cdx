require 'spec_helper'

describe Capability do
  # Crear un manifest
  it "creates a schema with string, enum and number fields" do
    field_mapping = %{
      [
        {
          "target_field": "started_at",
          "selector" : "started_at",
          "core" : true,
          "indexed" : true,
          "type" : "date"
        },
        {
          "target_field" : "results[*].result",
          "selector" : "result",
          "type" : "enum",
          "core" : true,
          "indexed" : true,
          "options" : [
            "positive",
            "negative"
          ]
        },
        {
          "target_field": "patient_name",
          "selector" : "patient_information.name",
          "core" : true,
          "indexed" : true,
          "type" : "string"
        },
        {
          "target_field": "age",
          "selector": "age",
          "type": "integer",
          "indexed" : "true",
          "core" : true,
          "valid_values" : {
            "range" : {
              "min" : 0,
              "max" : 125
            }
          }
        }
      ]
    }

    field_mapping = Oj.load(field_mapping)
    json_schema = Capability.new field_mapping, "first_assay", "es-AR"
    json_schema = json_schema.to_json

    json_schema["$schema"].should eq("http://json-schema.org/draft-04/schema#")
    json_schema["type"].should eq("object")
    json_schema["title"].should eq("first_assay.es-AR")

    schema_date = {
      "title" => "Started at",
      "type" => "string",
      "format" => "date-time",
      "resolution" => "day"
    }

    json_schema["properties"]["started_at"].should eq(schema_date)

    schema_enum = {
      "title" => "Result",
      "type" => "string",
      "enum" => ["positive","negative"]
    }

    json_schema["properties"]["result"].should eq(schema_enum)

    schema_string = {
      "title" => "Patient name",
      "type" => "string"
    }

    json_schema["properties"]["patient_name"].should eq(schema_string)

    schema_number = {
      "title" => "Age",
      "type" => "number",
      "minimum" => 0,
      "maximum" => 125
    }

    json_schema["properties"]["age"].should eq(schema_number)
  end

  it "creates a schema with location field" do
    root_location = Location.create_default
    parent_location = Location.make parent: root_location

    field_mapping = %{
      [
        {
          "target_field": "location",
          "selector" : "location",
          "core" : true,
          "indexed" : true,
          "type" : "location"
        }
      ]
    }

    field_mapping = Oj.load(field_mapping)
    json_schema = Capability.new field_mapping, "first_assay", "es-AR"
    json_schema = json_schema.to_json

    json_schema["$schema"].should eq("http://json-schema.org/draft-04/schema#")
    json_schema["type"].should eq("object")
    json_schema["title"].should eq("first_assay.es-AR")

    locations = Location.all
    schema_locations = {
      "#{locations[0].id.to_s}" => {"name" => locations[0].name, "level" => locations[0].depth, "parent" => locations[0].parent_id},
      "#{locations[1].id.to_s}" => {"name" => locations[1].name, "level" => locations[1].depth, "parent" => locations[1].parent_id}
    }

    schema_location = {
      "title" => "Location",
      "type" => "string",
      "enum" => locations.map { |l| l.id.to_s },
      "locations" => schema_locations
    }

    json_schema["properties"]["location"].should eq(schema_location)
  end

end
