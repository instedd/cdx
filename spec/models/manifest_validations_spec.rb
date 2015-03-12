require 'spec_helper'

describe Manifest do

  context "validations" do

    it "should apply if valid" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "assay_name",
              "source" : {"lookup" : "assay.name"},
              "type": "string",
              "core" : true
            }]
          }
        },
        '{"assay" : {"name" : "GX4002"}}',
        event: {indexed: {"assay_name" => "GX4002"}, pii: Hash.new, custom: Hash.new}
    end

    it "should not apply if invalid" do
      expect {
        assert_manifest_application %{
            {
              "event" : [{
                "target_field" : "assay_name",
                "source" : {"lookup" : "assay.name"},
                "type": "INVALID",
                "core" : true
              }]
            }
          },
          '{"assay" : {"name" : "GX4002"}}',
          event: {indexed: {"assay_name" => "GX4002"}, pii: Hash.new, custom: Hash.new}
      }.to raise_error(ManifestParsingError)
    end

    it "shouldn't pass validations when creating if definition is an invalid json" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0" , ,
          "api_version" : "1.0.0"
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:parse_error].should_not eq(nil)
    end

    it "shouldn't pass validations if metadata is empty" do
      definition = %{{
        "metadata" : {
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:metadata].first.should eq("can't be blank")
    end

    it "shouldn't pass validations if metadata doesn't include version" do
      definition = %{{
        "metadata" : {
          "api_version" : "1.1.0",
          "device_models" : ["GX4001"]
        },
        "field_mapping" : []
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:metadata].first.should eq("must include version field")
    end

    it "shouldn't pass validations if metadata doesn't include api_version" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "device_models" : ["GX4001"]
        },
        "field_mapping" : []
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:metadata].first.should eq("must include api_version field")
    end

    it "checks the version number against the current api version" do
      expect {Manifest.create!(definition: %{{
        "metadata" : {
          "device_models" : ["foo"],
          "api_version" : "1.1.1",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }})}.to raise_error("Validation failed: Api version must be 1.1.0")
    end

    it "shouldn't pass validations if metadata doesn't include device_models" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.0.0"
        },
        "field_mapping" : []
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:metadata].first.should eq("must include device_models field")
    end

    it "shouldn't pass validations if field_mapping is not an array" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0",
          "device_models" : ["GX4001"]
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:field_mapping].first.should eq("must be a json object")

      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0",
          "device_models" : ["GX4001"]
        },
        "field_mapping" : []
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:field_mapping].first.should eq("must be a json object")
    end

    pending "shouldn't create if a core field is provided with an invalid value mapping" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : [
          {
            "target_field" : "test_type",
            "source" : {
              "map" : [
                {"lookup" : "Test.test_type"},
                [
                  { "match" : "*QC*", "output" : "Invalid mapping"},
                  { "match" : "*Specimen*", "output" : "specimen"}
                ]
              ]
            },
            "type" : "enum",
            "core" : true,
            "options" : [ "qc", "specimen" ]
          }
        ]
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:invalid_field_mapping].first.should eq(": target 'test_type'. 'Invalid mapping' is not a valid value")
    end

    it "should create if core fields are provided with valid value mappings" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "event" : [
            {
              "target_field" : "test_type",
              "source" : {
                "map" : [
                  {"lookup" : "Test.test_type"},
                  [
                    { "match" : "*QC*", "output" : "qc"},
                    { "match" : "*Specimen*", "output" : "specimen"}
                  ]
                ]
              },
              "core" : true,
              "type" : "enum",
              "options" : ["qc", "specimen"]
            }
          ]
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(1)
    end

    it "shouldn't create if a core field is provided without source" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "event" : [
            {
              "target_field" : "results[*].result",
              "core" : true
            }
          ]
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:invalid_field_mapping].first.should eq(": target 'results[*].result'. Mapping must include 'target_field' and 'source' fields")
    end

    it "shouldn't create if a custom field is provided without type" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "event" : [
            {
              "target_field" : "patient_name",
              "source" : {"lookup" : "patient_name"},
              "core" : false
            }
          ]
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:invalid_type].first.should eq(": target 'patient_name'. Field type must be one of 'integer', 'long', 'float', 'double', 'date', 'enum', 'location', 'boolean' or 'string'")
    end

    it "shouldn't create if a custom field is provided with an invalid type" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "event" : [
            {
              "target_field" : "patient_name",
              "source" : {"lookup" : "patient_name"},
              "type" : "quantity",
              "core" : false
            }
          ]
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:invalid_type].first.should eq(": target 'patient_name'. Field type must be one of 'integer', 'long', 'float', 'double', 'date', 'enum', 'location', 'boolean' or 'string'")
    end

    it "should create when fields are provided with valid types" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "event" : [
            {
              "target_field" : "patient_name",
              "source" : {"lookup" : "patient_name"},
              "type" : "string",
              "core" : false
            },
            {
              "target_field" : "control_date",
              "source" : {"lookup": "control_date"},
              "type" : "date",
              "core" : false
            },
            {
              "target_field" : "rbc_count",
              "source" : {"lookup": "rbc_count"},
              "type" : "integer",
              "core" : false
            }
          ]
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(1)
    end

    it "shouldn't create if string 'null' appears as valid value of some field" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "event" : [
            {
              "target_field" : "rbc_description",
              "source" : {"lookup" : "rbc_description"},
              "type" : "enum",
              "core" : false,
              "options" : ["high","low","null"]
            }
          ]
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:string_null].first.should eq(": cannot appear as a possible value. (In 'rbc_description') ")
    end

    it "shouldn't create if an enum field is provided without options" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "event" : [
            {
              "target_field" : "results[*].result",
              "source" : {"lookup" : "result"},
              "core" : true,
              "type" : "enum"
            }
          ]
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:enum_fields].first.should eq("must be provided with options. (In 'results[*].result'")
    end
  end
end
