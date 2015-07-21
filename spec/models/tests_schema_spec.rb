require 'spec_helper'

describe TestsSchema do

  before(:each) do
    sample_fields = [
      {
        name: 'uuid',
        searchable: true
      }
    ]

    patient_fields = [
      {
        name: 'age',
        type: 'integer'
      },
      {
        name: 'gender',
        type: 'enum',
        options: ['male', 'female']
      }
    ]

    location_fields = [
      {name: 'lat'},
      {name: 'lng'},
    ]

    sample_scope = Cdx::Scope.new('sample', sample_fields)
    patient_scope = Cdx::Scope.new('patient', patient_fields)
    location_scope = Cdx::Scope.new('location', location_fields)

    Cdx.stub(:core_field_scopes).and_return([sample_scope, patient_scope, location_scope])
  end

  it "creates a schema with string, enum and number fields" do
    schema = TestsSchema.new("es-AR").build

    schema["$schema"].should eq("http://json-schema.org/draft-04/schema#")
    schema["type"].should eq("object")
    schema["title"].should eq("es-AR")

    schema["properties"]["sample"].should eq({
      "type" => "object",
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
    schema = TestsSchema.new("es-AR").build

    schema["properties"]["location"]["location-service"].should eq({
      url: Settings.location_service_url,
      set: Settings.location_service_set
    }.with_indifferent_access)
  end

end
