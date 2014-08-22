require 'spec_helper'

describe Event do
  it 'stores failed events with raw data when it hits an issue parsing a manifest' do
    model = DeviceModel.make
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

    e = Event.create_or_update_with device, json

    expect(e.new_record?).to be_false
    expect(e.index_failed?).to be_true
    expect(e.index_failure_reason).to eq(ManifestParsingError.invalid_value_for_integer("foo", "error_code").message)
  end
end
