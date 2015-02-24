require 'spec_helper'

describe EventsSchema do
  let!(:root_location) { Location.create_default }
  let!(:parent_location) { Location.make parent: root_location }

  # Crear un manifest
  it "creates a schema with string, enum and number fields" do
    definition = %{{
      "field_mapping" : {
        "event" : [
          {
            "target_field" : "start_time",
            "source" : {"lookup" : "start_time"},
            "core" : true,
            "indexed" : true,
            "type" : "date"
          },
          {
            "target_field" : "results[*].result",
            "source" : {"lookup" : "result"},
            "type" : "enum",
            "core" : true,
            "indexed" : true,
            "options" : [
              "positive",
              "positive_with_riff",
              "negative"
            ]
          }
        ],
        "patient" : [
          {
            "target_field" : "patient_name",
            "source" : {"lookup" : "patient_information.name"},
            "core" : true,
            "indexed" : true,
            "type" : "string"
          },
          {
            "target_field" : "age",
            "source" : {"lookup" : "age"},
            "type" : "integer",
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
    }}

    date_schema = {
      "title" => "Start Time",
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

    schema = EventsSchema.new "es-AR", "first_assay", Manifest.new(definition:definition)
    schema = schema.build

    schema["$schema"].should eq("http://json-schema.org/draft-04/schema#")
    schema["type"].should eq("object")
    schema["title"].should eq("first_assay.es-AR")

    schema["properties"]["start_time"].should eq(date_schema)
    schema["properties"]["result"].should eq(enum_schema)
    schema["properties"]["patient_name"].should eq(string_schema)
    schema["properties"]["age"].should eq(number_schema)
  end

  it "creates a schema with location field" do
    definition = %{{
      "field_mapping" : { "patient" : [
        {
          "target_field" : "patient_location",
          "source" : {"lookup" : "patient_location"},
          "core" : true,
          "indexed" : true,
          "type" : "location"
        }
      ]}
    }}

    locations = Location.all
    location_schema = {
      "title" => "Patient Location",
      "type" => "string",
      "enum" => [ root_location.geo_id.to_s, parent_location.geo_id.to_s ],
      "locations" => {
        "#{root_location.geo_id.to_s}" => {"name" => root_location.name, "level" => root_location.admin_level, "parent" => nil, "lat" => root_location.lat, "lng" => root_location.lng},
        "#{parent_location.geo_id.to_s}" => {"name" => parent_location.name, "level" => parent_location.admin_level, "parent" => root_location.geo_id, "lat" => parent_location.lat, "lng" => parent_location.lng}
      }
    }

    schema = EventsSchema.new "es-AR", "first_assay", Manifest.new(definition:definition)
    schema = schema.build

    schema["$schema"].should eq("http://json-schema.org/draft-04/schema#")
    schema["type"].should eq("object")
    schema["title"].should eq("first_assay.es-AR")

    schema["properties"]["patient_location"].should eq(location_schema)
  end

  it "should return an empty schema with all the assay_names available if none is provided" do
    Manifest.create definition: %{{
      "metadata" : {
        "device_models" : ["foo"],
        "api_version" : "1.0.0",
        "version" : "1.0.1"
      },
      "field_mapping" : { "event" : [
        {
          "target_field" : "assay_name",
          "source" : {"lookup" : "assay_name"},
          "core" : true,
          "indexed" : true,
          "type" : "enum",
          "options" : [
            "first_assay",
            "second_assay"
          ]
        }
      ]}
    }}

    manifest = Manifest.create definition: %{{
      "metadata" : {
        "device_models" : ["bar"],
        "api_version" : "1.0.0",
        "version" : "1.0.1"
      },
      "field_mapping" : { "event" : [
        {
          "target_field" : "assay_name",
          "source" : {"lookup" : "assay_name"},
          "core" : true,
          "indexed" : true,
          "type" : "enum",
          "options" : [
            "cardridge_1",
            "cardridge_2"
          ]
        }
      ]}
    }}

    schema = EventsSchema.for "es-AR"
    schema = schema.build

    schema["$schema"].should eq("http://json-schema.org/draft-04/schema#")
    schema["type"].should eq("object")
    schema["title"].should eq("es-AR")

    schema["properties"]["assay_name"].should eq({
      "title" => "Assay Name",
      "type" => "string",
      "enum" => ["first_assay", "second_assay", "cardridge_1", "cardridge_2"],
      "values" => {
        "first_assay" => {"name" => "First Assay"},
        "second_assay" => {"name" => "Second Assay"},
        "cardridge_1" => {"name" => "Cardridge 1"},
        "cardridge_2" => {"name" => "Cardridge 2"}
      }
    })
  end
end
