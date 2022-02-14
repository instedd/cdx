require 'spec_helper'

describe DeviceMessage, elasticsearch: true do
  let(:device) { Device.make! device_model: DeviceModel.make! }

  it 'stores failed messages with raw data when it hits an issue parsing a manifest' do
    manifest = Manifest.create! device_model: device.device_model, definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "#{Manifest::CURRENT_VERSION}",
          "conditions": ["mtb"],
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
    manifest = Manifest.create! device_model: device.device_model, definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "#{Manifest::CURRENT_VERSION}",
          "conditions": ["mtb"],
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
    manifest = Manifest.create! device_model: device.device_model, definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "#{Manifest::CURRENT_VERSION}",
          "conditions": ["mtb"],
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
    let(:device_message) { DeviceMessage.make! }

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

  context "within" do
    let!(:site) { Site.make! }
    let!(:subsite) { Site.make! parent: site, institution: site.institution }
    let!(:other_site) { Site.make! }
    let!(:device1) { Device.make! site: site, institution: site.institution }
    let!(:device2) { Device.make! site: subsite, institution: site.institution }
    let!(:device3) { Device.make! site: other_site, institution: other_site.institution }
    let!(:device4) { Device.make! site: nil, institution: site.institution }
    let!(:device_message1) { DeviceMessage.make! device: device1 }
    let!(:device_message2) { DeviceMessage.make! device: device2 }
    let!(:device_message3) { DeviceMessage.make! device: device3 }
    let!(:device_message4) { DeviceMessage.make! device: device4 }

    it "institution, no exclusion, should show device messages from site, subsites and no site" do
      expect(DeviceMessage.within(site.institution).to_a).to eq([device_message1, device_message2, device_message4])
    end

    it "institution, with exclusion, should show device messages with no site" do
      expect(DeviceMessage.within(site.institution,true).to_a).to eq([device_message4])
    end

    it "site, no exclusion, should show device messages from site and subsite" do
      expect(DeviceMessage.within(site).to_a).to eq([device_message1, device_message2])
    end

    it "site, with exclusion, should show device messages from site only" do
      expect(DeviceMessage.within(site,true).to_a).to eq([device_message1])
    end

    it "institution should not show device messages from other institutions" do
      expect(DeviceMessage.within(other_site.institution).to_a).to eq([device_message3])
    end

  end
end
