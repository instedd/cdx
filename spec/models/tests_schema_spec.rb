require 'spec_helper'

describe TestsSchema do
  it "creates a schema with string, enum and number fields" do
    sample_fields = {
      "uuid" => {
        "searchable" => true,
      }
    }

    patient_fields = {
      "age" => {
        "type" => "integer"
      },
      "gender" => {
        "type" => 'enum',
        "options" => ['male', 'female']
      }
    }

    sample_scope = Cdx::Scope.new('sample', sample_fields)
    patient_scope = Cdx::Scope.new('patient', patient_fields)
    Cdx.stub(:core_field_scopes).and_return([sample_scope, patient_scope])

    schema = TestsSchema.new("es-AR").build

    schema["$schema"].should eq("http://json-schema.org/draft-04/schema#")
    schema["type"].should eq("object")
    schema["title"].should eq("es-AR")

    schema["properties"]["sample"].should eq({
      "type" => "object",
      "title" => "Sample",
      "properties" => {
        "uuid" => {
          "title" => "Uuid",
          "type" => "string",
          "searchable" => true
        },
      }
    })

    schema["properties"]["patient"].should eq({
      "type" => "object",
      "title" => "Patient",
      "properties" => {
        "age" => {
          "title" => "Age",
          "type" => "integer",
          "searchable" => false
        },
        "gender" => {
          "title" => "Gender",
          "type" => "string",
          "enum" => ["male", "female"],
          "values" => {
            "male" => { "name" => "Male" },
            "female" => { "name" => "Female" }
          },
          "searchable" => false
        }
      }
    })
  end

  it "should add location service properties to location scope" do
    location_fields = {
      "lat" => {},
      "lng" => {},
    }

    location_scope = Cdx::Scope.new('location', location_fields)
    Cdx.stub(:core_field_scopes).and_return([location_scope])

    schema = TestsSchema.new("es-AR").build

    schema["properties"]["location"]["location-service"].should eq({
      "url" => Settings.location_service_url,
      "set" => Settings.location_service_set
    })
  end

  it "shows condition field as enum" do
    Condition.create! name: "foo"
    Condition.create! name: "bar"
    schema = TestsSchema.new("es-AR").build

    condition_field = schema["properties"]["test"]["properties"]["assays"]["items"]["properties"]["condition"]
    condition_field["enum"].should eq(["bar", "foo"])
  end

end
