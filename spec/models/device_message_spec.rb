require 'spec_helper'

describe DeviceMessage, elasticsearch: true do
  let(:device) {Device.make device_model: DeviceModel.make(manifests: [])}

  it 'stores failed messages with raw data when it hits an issue parsing a manifest' do
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "#{Manifest::CURRENT_VERSION}",
          "device_models": "#{device.device_model.name}",
          "conditions": ["MTB"],
          "source" : { "type" : "json"}
        },
        "field_mapping" : {
          "test.error_code" : {"lookup": "error_code"}
        }
      }
    }

    json = %{{ "error_code": "foo" }}

    message = DeviceMessage.new(device:device, plain_text_data: json)

    expect(message.save).to eq(true)
    expect(message.index_failed?).to eq(true)
    expect(message.index_failure_reason).to eq(ManifestParsingError.invalid_value_for_integer("foo", "test.error_code").message)
    expect(message.index_failure_data[:target_field]).to eq('test.error_code')
  end

  it "stores failed messages when the string 'null' is passed as value" do
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "#{Manifest::CURRENT_VERSION}",
          "device_models": "#{device.device_model.name}",
          "conditions": ["MTB"],
          "source" : { "type" : "json"}
        },
        "field_mapping" : {
          "test.assays.result" : {"lookup": "result"}
        }
      }
    }

    json = %{{ "result": "null" }}

    message = DeviceMessage.new(device:device, plain_text_data: json)

    expect(message.save).to eq(true)
    expect(message.index_failed?).to eq(true)
    expect(message.index_failure_reason).to eq("String 'null' is not permitted as value, in field 'test.assays.result'")
    expect(message.index_failure_data[:target_field]).to eq('test.assays.result')
  end

  it 'parses a csv with a single row' do
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "#{Manifest::CURRENT_VERSION}",
          "device_models": "#{device.device_model.name}",
          "conditions": ["MTB"],
          "source" : { "type" : "csv"}
        },
        "field_mapping" : {
          "test.error_code" : {"lookup": "error_code"},
          "test.assays.result" : {"lookup": "result"}
        }
      }
    }

    csv = %{error_code,result\n0,positive}

    message = DeviceMessage.new(device:device, plain_text_data: csv)

    expect(message.save).to eq(true)
    expect(message.index_failed?).to eq(false)
  end

  context 'reprocess' do
    let(:device_message) { DeviceMessage.make }

    before(:each) do
      expect(device_message).to receive(:clear_errors)
      expect(device_message).to receive(:save)
    end

    it 'should process if index did not failed' do
      expect(device_message).to receive(:index_failed).and_return(false)
      expect(device_message).to receive(:process)

      device_message.reprocess
    end

    it "should not process if index failed" do
      expect(device_message).to receive(:index_failed).and_return(true)
      expect(device_message).not_to receive(:process)

      device_message.reprocess
    end
  end
end
