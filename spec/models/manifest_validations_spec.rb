require 'spec_helper'

describe Manifest do

  context "validations" do

    it "should apply if valid" do
      assert_manifest_application %{
          {
            "test.name": {"lookup" : "assay.name"}
          }
        }, %{
          {}
        },
        '{"assay" : {"name" : "GX4002"}}',
        "test" => {"core" => {"name" => "GX4002"}, "pii" => {}, "custom" => {}}
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
          "test" => {"core" => {"assay_name" => "GX4002"}, "pii" => {}, "custom" => {}}
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
          "conditions": ["MTB"],
          "api_version" : "1.1.1",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }})}.to raise_error("Validation failed: Api version must be #{Manifest::CURRENT_VERSION}")
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

    it "shouldn't pass validations if custom_fields is not an object" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "device_models" : ["GX4001"]
        },
        "custom_fields": [],
        "field_mapping" : {}
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:custom_fields].first.should eq("must be a json object")
    end

    it "shouldn't create if a custom field is provided with an invalid type" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "custom_fields": {
          "test.custom": {
            "type": "quantity"
          }
        },
        "field_mapping" : {
          "test.custom": {"lookup" : "test.custom"}
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:invalid_type].first.should eq(": target 'test.custom'. Field can't specify a type.")
    end

    it "should create when fields are provided with no types" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "device_models" : ["GX4001"],
          "conditions" : ["MTB"],
          "source" : {"type" : "json"}
        },
        "custom_fields": {
          "patient.name": {
          },
          "patient.control_date": {
          },
          "patient.rbc_count": {
          }
        },
        "field_mapping" : {
          "patient.name": {"lookup" : "patient.name"},
          "patient.control_date": {"lookup": "patient.control_date"},
          "patient.rbc_count": {"lookup": "patient.rbc_count"}
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(1)
    end

    it "shouldn't create if missing conditions" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "device_models" : ["GX4001"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "custom": {"lookup" : "custom"}
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:metadata].first.should eq("must include conditions field")
    end

    it "shouldn't create if conditions is not an array" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "device_models" : ["GX4001"],
          "conditions": 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "custom": {"lookup" : "custom"}
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:conditions].first.should eq("must be a json array")
    end

    it "shouldn't create if conditions is an empty array" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "device_models" : ["GX4001"],
          "conditions": [],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "custom": {"lookup" : "custom"}
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:conditions].first.should eq("must be a non-empty json array")
    end

    it "shouldn't create if conditions is not a string array" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "device_models" : ["GX4001"],
          "conditions": ["foo", 1],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "custom": {"lookup" : "custom"}
        }
      }}
      m = Manifest.new(definition: definition)
      m.save
      Manifest.count.should eq(0)
      m.errors[:conditions].first.should eq("must be a json string array")
    end
  end
end
