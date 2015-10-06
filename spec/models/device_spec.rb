require 'spec_helper'

describe Device do

  context "validations" do

    it { is_expected.to validate_presence_of :device_model }
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :institution }

    it "should validate unpublished device model to belong to the same institution" do
      device = Device.make_unsaved
      device.institution = Institution.make
      device.device_model = DeviceModel.make(:unpublished, institution: Institution.make)
      expect(device).to be_invalid

      device.device_model = DeviceModel.make(:unpublished, institution: device.institution)
      expect(device).to be_valid
    end

    it "should not validate published device model" do
      device = Device.make_unsaved
      device.institution = Institution.make
      device.device_model = DeviceModel.make(institution: Institution.make)
      expect(device).to be_valid
    end

  end



  context 'secret key' do
    let(:device) { Device.new }

    before(:each) do
      expect(MessageEncryption).to receive(:secure_random).and_return('abc')
    end

    it 'should tell plain secret key' do
      device.set_key

      expect(device.plain_secret_key).to eq('abc')
    end

    it 'should store hashed secret key' do
      device.set_key

      expect(device.secret_key_hash).to eq(MessageEncryption.hash 'abc')
    end
  end

  context 'commands' do
    let(:device) { Device.make }

    it "doesn't have pending log requests" do
      expect(device.has_pending_log_requests?).to be(false)
    end

    it "has pending log requests" do
      device.request_client_logs
      expect(device.has_pending_log_requests?).to be(true)

      commands = device.device_commands.all
      expect(commands.count).to eq(1)
      expect(commands[0].name).to eq("send_logs")
      expect(commands[0].command).to be_nil
    end
  end
end
