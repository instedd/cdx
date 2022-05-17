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
          "version" : "1.0.0",
          "api_version" : "1.0.0"
        }
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:definition]).not_to eq(nil)
    end

    it "shouldn't pass validations if metadata is empty" do
      definition = %{{
        "metadata" : {
        }
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:metadata].first).to eq("can't be blank")
    end

    it "shouldn't pass validations if metadata doesn't include version" do
      definition = %{{
        "metadata" : {
          "api_version" : "1.1.0"
        },
        "field_mapping" : []
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:metadata].first).to eq("must include version field")
    end

    it "shouldn't pass validations if metadata doesn't include api_version" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0"
        },
        "field_mapping" : []
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:metadata].first).to eq("must include api_version field")
    end

    it "checks the version number against the current api version" do
      expect {Manifest.make!(definition: %{{
        "metadata" : {
          "conditions": ["mtb"],
          "api_version" : "1.1.1",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }})}.to raise_error("Validation failed: Api version must be #{Manifest::CURRENT_VERSION}")
    end

    it "shouldn't pass validations if field_mapping is not an array" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0"
        }
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:field_mapping].first).to eq("must be a json object")

      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "1.1.0"
        },
        "field_mapping" : []
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:field_mapping].first).to eq("must be a json object")
    end

    it "shouldn't pass validations if custom_fields is not an object" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}"
        },
        "custom_fields": [],
        "field_mapping" : {}
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:custom_fields].first).to eq("must be a json object")
    end

    it "shouldn't create if a custom field is provided with an invalid type" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
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
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:invalid_type].first).to eq(": target 'test.custom'. Field can't specify a type.")
    end

    it "shouldn't create if a custom field has a nonexistent scope" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "conditions" : ["mtb"],
          "source" : {"type" : "json"}
        },
        "custom_fields": {
          "nonexistent.custom": {
          }
        },
        "field_mapping" : {
          "nonexistent.custom": {"lookup" : "test.custom"}
        }
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      expect(m).to be_invalid
      expect(m.errors[:custom_fields]).to contain_exactly(": target 'nonexistent.custom'. Scope 'nonexistent' is invalid.")
    end

    it "shouldn't create if a custom field has no scope" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "conditions" : ["mtb"],
          "source" : {"type" : "json"}
        },
        "custom_fields": {
          "custom": {
          }
        },
        "field_mapping" : {
          "custom": {"lookup" : "test.custom"}
        }
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      expect(m).to be_invalid
      expect(m.errors[:custom_fields]).to contain_exactly(": target 'custom'. A scope must be specified.")
    end

    it "should create when fields are provided with no types" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "conditions" : ["mtb"],
          "source" : {"type" : "json"}
        },
        "custom_fields": {
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
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(1)
    end

    it "shouldn't create if missing conditions" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "custom": {"lookup" : "custom"}
        }
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:metadata].first).to eq("must include conditions field")
    end

    it "shouldn't create if conditions is not an array" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "conditions": 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "custom": {"lookup" : "custom"}
        }
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:conditions].first).to eq("must be a json array")
    end

    it "shouldn't create if conditions is an empty array" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "conditions": [],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "custom": {"lookup" : "custom"}
        }
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:conditions].first).to eq("must be a non-empty json array")
    end

    it "shouldn't create if conditions is not a string array" do
      definition = %{{
        "metadata" : {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "conditions": ["foo", 1],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "custom": {"lookup" : "custom"}
        }
      }}
      m = Manifest.new(device_model: DeviceModel.make!, definition: definition)
      m.save
      expect(Manifest.count).to eq(0)
      expect(m.errors[:conditions].first).to eq("must be a json string array")
    end
  end
end
