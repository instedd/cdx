require 'spec_helper'

describe DeviceMessage, elasticsearch: true do
  let(:device) {Device.make}

  it 'stores failed messages with raw data when it hits an issue parsing a manifest' do
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1.1.0",
          "device_models": "#{device.device_model.name}",
          "source" : { "type" : "json"}
        },
        "field_mapping" : {"test" :[{
            "target_field" : "error_code",
            "source" : {"lookup": "error_code"},
            "core" : true,
            "type" : "integer"
        }]}
      }
    }

    json = %{{ "error_code": "foo" }}

    message = DeviceMessage.new(device:device, plain_text_data: json)

    expect(message.save).to be_true
    expect(message.index_failed?).to be_true
    expect(message.index_failure_reason).to eq(ManifestParsingError.invalid_value_for_integer("foo", "error_code").message)
    expect(message.index_failure_data[:target_field]).to eq('error_code')
  end

  it "stores failed messages when the string 'null' is passed as value" do
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1.1.0",
          "device_models": "#{device.device_model.name}",
          "source" : { "type" : "json"}
        },
        "field_mapping" : { "test" : [{
            "target_field" : "results[*].result",
            "source" : {"lookup": "result"},
            "core" : true,
            "type" : "enum",
            "options" : ["positive","negative"]
        }]}
      }
    }

    json = %{{ "result": "null" }}

    message = DeviceMessage.new(device:device, plain_text_data: json)

    expect(message.save).to be_true
    expect(message.index_failed?).to be_true
    expect(message.index_failure_reason).to eq("String 'null' is not permitted as value, in field 'results[*].result'")
    expect(message.index_failure_data[:target_field]).to eq('results[*].result')
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
        "field_mapping" : { "test" : [{
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

    message = DeviceMessage.new(device:device, plain_text_data: csv)

    expect(message.save).to be_true
    expect(message.index_failed?).to be_false
  end

  context 'reprocess' do
    let(:device_message) { DeviceMessage.make }

    before(:each) do
      device_message.should_receive(:clear_errors)
      device_message.should_receive(:save)
    end

    it 'should process if index did not failed' do
      device_message.should_receive(:index_failed).and_return(false)
      device_message.should_receive(:process)

      device_message.reprocess
    end

    it "should not process if index failed" do
      device_message.should_receive(:index_failed).and_return(true)
      device_message.should_not_receive(:process)

      device_message.reprocess
    end
  end
end
