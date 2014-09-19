require 'spec_helper'

describe EventsSchema do
  let!(:root_location) { Location.create_default }
  let!(:parent_location) { Location.make parent: root_location }

  # Crear un manifest
  it "creates a schema with string, enum and number fields" do
    definition = %{{
      "field_mapping" : [
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
            "positive_with_riff",
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
    }}

    date_schema = {
      "title" => "Started At",
      "type" => "string",
      "format" => "date-time",
      "resolution" => "second"
    }

    enum_schema = {
      "title" => "Result",
      "type" => "string",
      "enum" => ["positive", "positive_with_riff", "negative"],
      "values" => {
        "positive" => { "name" => "Positive", "kind" => "positive" },
        "positive_with_riff" => { "name" => "Positive With Riff", "kind" => "positive" },
        "negative" => { "name" => "Negative", "kind" => "negative" }
      }
    }

    string_schema = {
      "title" => "Patient Name",
      "type" => "string"
    }

    number_schema = {
      "title" => "Age",
      "type" => "integer",
      "minimum" => 0,
      "maximum" => 125
    }

    json_schema = EventsSchema.new Manifest.new(definition:definition), "first_assay", "es-AR"
    json_schema = json_schema.schema

    json_schema["$schema"].should eq("http://json-schema.org/draft-04/schema#")
    json_schema["type"].should eq("object")
    json_schema["title"].should eq("first_assay.es-AR")

    json_schema["properties"]["started_at"].should eq(date_schema)
    json_schema["properties"]["result"].should eq(enum_schema)
    json_schema["properties"]["patient_name"].should eq(string_schema)
    json_schema["properties"]["age"].should eq(number_schema)
  end

  it "creates a schema with location field" do
    definition = %{{
      "field_mapping" :[
        {
          "target_field": "patient_location",
          "selector" : "patient_location",
          "core" : true,
          "indexed" : true,
          "type" : "location"
        }
      ]
    }}

    locations = Location.all
    location_schema = {
      "title" => "Patient Location",
      "type" => "string",
      "enum" => [ root_location.id.to_s, parent_location.id.to_s ],
      "locations" => {
        "#{root_location.id.to_s}" => {"name" => root_location.name, "level" => root_location.admin_level, "parent" => root_location.parent_id},
        "#{parent_location.id.to_s}" => {"name" => parent_location.name, "level" => parent_location.admin_level, "parent" => parent_location.parent_id}
      }
    }

    json_schema = EventsSchema.new Manifest.new(definition:definition), "first_assay", "es-AR"
    json_schema = json_schema.schema

    json_schema["$schema"].should eq("http://json-schema.org/draft-04/schema#")
    json_schema["type"].should eq("object")
    json_schema["title"].should eq("first_assay.es-AR")

    json_schema["properties"]["patient_location"].should eq(location_schema)
  end
end
