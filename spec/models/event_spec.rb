require 'spec_helper'

describe Event do
  let(:model){DeviceModel.make}

  it 'stores failed events with raw data when it hits an issue parsing a manifest' do
    manifest = Manifest.make definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1",
          "device_models": "#{model.name}"
        },
        "field_mapping" : [{
            "target_field" : "error_code",
            "selector" : "error_code",
            "core" : true,
            "type" : "integer"
        }]
      }
    }

    device = Device.make device_model: model
    json = %{{ "error_code": "foo" }}

    e, saved = Event.create_or_update_with device, json

    expect(saved).to be_true
    expect(e.index_failed?).to be_true
    expect(e.index_failure_reason).to eq(ManifestParsingError.invalid_value_for_integer("foo", "error_code").message)
  end

  it "stores failed events when the string 'null' is passed as value" do
    manifest = Manifest.make definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1",
          "device_models": "#{model.name}"
        },
        "field_mapping" : [{
            "target_field" : "results[*].result",
            "selector" : "result",
            "core" : true,
            "type" : "enum",
            "options" : ["positive","negative"]
        }]
      }
    }

    device = Device.make device_model: model
    json = %{{ "result": "null" }}

    e, saved = Event.create_or_update_with device, json

    expect(saved).to be_true
    expect(e.index_failed?).to be_true
    expect(e.index_failure_reason).to eq("String 'null' is not permitted as value, in field 'results[*].result'")
  end
end
