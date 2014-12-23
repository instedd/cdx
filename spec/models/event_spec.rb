require 'spec_helper'

describe Event do
  let(:device) {Device.make}

  it 'stores failed events with raw data when it hits an issue parsing a manifest' do
    manifest = Manifest.make definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1",
          "device_models": "#{device.device_model.name}",
          "source_data_type" : "json"
        },
        "field_mapping" : [{
            "target_field" : "error_code",
            "source" : {"lookup": "error_code"},
            "core" : true,
            "type" : "integer"
        }]
      }
    }

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
          "device_models": "#{device.device_model.name}",
          "source_data_type" : "json"
        },
        "field_mapping" : [{
            "target_field" : "results[*].result",
            "source" : {"lookup": "result"},
            "core" : true,
            "type" : "enum",
            "options" : ["positive","negative"]
        }]
      }
    }

    json = %{{ "result": "null" }}

    e, saved = Event.create_or_update_with device, json

    expect(saved).to be_true
    expect(e.index_failed?).to be_true
    expect(e.index_failure_reason).to eq("String 'null' is not permitted as value, in field 'results[*].result'")
  end

  it 'parses a csv with a single row' do
    manifest = Manifest.make definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1",
          "device_models": "#{device.device_model.name}",
          "source_data_type" : "csv"
        },
        "field_mapping" : [{
            "target_field" : "error_code",
            "source" : {"lookup": "error_code"},
            "core" : true,
            "type" : "integer"
          },
          {
            "target_field" : "result",
            "source" : {"lookup": "result"},
            "core" : true,
            "type" : "enum",
            "options" : [ "positive", "negative" ]
          }
        ]
      }
    }

    csv = %{error_code,result\n0,positive}

    e, saved = Event.create_or_update_with device, csv

    expect(saved).to be_true
    expect(e.index_failed?).to be_false
  end
end
