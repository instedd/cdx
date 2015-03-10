require 'spec_helper'

describe DeviceEvent, elasticsearch: true do
  let(:device) {Device.make}

  it 'stores failed events with raw data when it hits an issue parsing a manifest' do
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1.1.0",
          "device_models": "#{device.device_model.name}",
          "source" : { "type" : "json"}
        },
        "field_mapping" : {"event" :[{
            "target_field" : "error_code",
            "source" : {"lookup": "error_code"},
            "core" : true,
            "type" : "integer"
        }]}
      }
    }

    json = %{{ "error_code": "foo" }}

    event = DeviceEvent.new(device:device, plain_text_data: json)

    expect(event.save).to be_true
    expect(event.index_failed?).to be_true
    expect(event.index_failure_reason).to eq(ManifestParsingError.invalid_value_for_integer("foo", "error_code").message)
  end

  it "stores failed events when the string 'null' is passed as value" do
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1.1.0",
          "device_models": "#{device.device_model.name}",
          "source" : { "type" : "json"}
        },
        "field_mapping" : { "event" : [{
            "target_field" : "results[*].result",
            "source" : {"lookup": "result"},
            "core" : true,
            "type" : "enum",
            "options" : ["positive","negative"]
        }]}
      }
    }

    json = %{{ "result": "null" }}

    event = DeviceEvent.new(device:device, plain_text_data: json)

    expect(event.save).to be_true
    expect(event.index_failed?).to be_true
    expect(event.index_failure_reason).to eq("String 'null' is not permitted as value, in field 'results[*].result'")
  end

  it 'parses a csv with a single row' do
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1.1.0",
          "device_models": "#{device.device_model.name}",
          "source" : { "type" : "csv"}
        },
        "field_mapping" : { "event" : [{
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
        ]}
      }
    }

    csv = %{error_code,result\n0,positive}

    event = DeviceEvent.new(device:device, plain_text_data: csv)

    expect(event.save).to be_true
    expect(event.index_failed?).to be_false
  end
end
