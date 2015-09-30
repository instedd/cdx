require 'spec_helper'

describe DeviceLogsController do
  let(:institution) {Institution.make}
  let(:device) { Device.make institution: institution}

  before(:each) do
    device.set_key_for_activation_token
    @plain_secret_key = device.plain_secret_key
    device.save!
  end

  describe "create" do
    it "creates" do
      post :create, "Some failure", device_id: device.uuid, key: @plain_secret_key
      expect(DeviceLog.count).to eq(1)
    end

    it "returns forbidden if wrong key" do
      post :create, "Some failure", device_id: device.uuid, key: "#{@plain_secret_key}..."
      expect(response).to be_forbidden
    end
  end
end
