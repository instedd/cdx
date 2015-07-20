require 'spec_helper'

describe Manifest do

  context "validations" do

    it "should apply if valid" do
      assert_manifest_application %{
          {
            "test.name": {"lookup" : "assay.name"}
          }
        }, %{
          []
        },
        '{"assay" : {"name" : "GX4002"}}',
        test: {indexed: {"name" => "GX4002"}, pii: Hash.new, custom: Hash.new}
    end

    it "should not apply if invalid" do
      expect {
        assert_manifest_application %{
            {
              "test.custom": {"lookup" : "assay.name"}
            }
          }, %{
            [
              {
                "name": "test.custom",
                "type": "INVALID"
              }
            ]
          },
          '{"assay" : {"name" : "GX4002"}}',
          test: {indexed: {"assay_name" => "GX4002"}, pii: Hash.new, custom: Hash.new}
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
      }})}.to raise_error("Validation failed: Api version must be 1.2.0")
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

    it "shouldn't pass validations if custom_fields is not an array" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.2.0",
          "device_models" : ["GX4001"]
        },
        "custom_fields": {},
        "field_mapping" : {}
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:custom_fields].first.should eq("must be a json array")
    end

    pending "shouldn't create if a custom field is provided with an invalid value mapping" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.2.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "custom_fields": [
          {
            "name": "custom",
            "type" : "enum",
            "options" : [ "qc", "specimen" ]
          }
        ],
        "field_mapping" : {
          "custom": {
            "map" : [
              {"lookup" : "Test.test_type"},
              [
                { "match" : "*QC*", "output" : "Invalid mapping"},
                { "match" : "*Specimen*", "output" : "specimen"}
              ]
            ]
          }
        }
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
          "api_version" : "1.2.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "custom_fields": [
          {
            "name": "test.custom",
            "type" : "enum",
            "options" : ["qc", "specimen"]
          }
        ],
        "field_mapping" : {
          "test.custom": {
            "map" : [
              {"lookup" : "Test.test_type"},
              [
                { "match" : "*QC*", "output" : "qc"},
                { "match" : "*Specimen*", "output" : "specimen"}
              ]
            ]
          }
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(1)
    end

    it "shouldn't create if a custom field is provided without type" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.2.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "custom_fields": [
          {
            "name": "test.custom"
          }
        ],
        "field_mapping" : {
          "test.custom": {"lookup" : "custom"}
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:invalid_type].first.should eq(": target 'test.custom'. Field type must be one of 'integer', 'long', 'float', 'double', 'date', 'enum', 'location', 'boolean' or 'string'")
    end

    it "shouldn't create if a custom field is provided with an invalid type" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.2.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "custom_fields": [
          {
            "name": "test.custom",
            "type": "quantity"
          }
        ],
        "field_mapping" : {
          "test.custom": {"lookup" : "custom"}
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:invalid_type].first.should eq(": target 'test.custom'. Field type must be one of 'integer', 'long', 'float', 'double', 'date', 'enum', 'location', 'boolean' or 'string'")
    end

    it "should create when fields are provided with valid types" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.2.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "custom_fields": [
          {
            "name": "patient_name",
            "type" : "string"
          },
          {
            "name": "control_date",
            "type" : "date"
          },
          {
            "name": "rbc_count",
            "type" : "integer"
          }
        ],
        "field_mapping" : {
          "patient_name": {"lookup" : "patient_name"},
          "control_date": {"lookup": "control_date"},
          "rbc_count": {"lookup": "rbc_count"}
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
          "api_version" : "1.2.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "custom_fields": [
          {
            "name": "rbc_description",
            "type" : "enum",
            "options" : ["high","low","null"]
          }
        ],
        "field_mapping" : {
          "rbc_description": {"lookup" : "rbc_description"}
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
          "api_version" : "1.2.0",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "custom_fields": [
          {
            "name": "custom",
            "type" : "enum"
          }
        ],
        "field_mapping" : {
          "custom": {"lookup" : "custom"}
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:enum_fields].first.should eq("must be provided with options. (In 'custom'")
    end
  end
end
