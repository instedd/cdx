require 'spec_helper'

describe DeviceLogsController do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
    @device = Device.make! institution: @institution
  end

  before(:each) do
    device.set_key_for_activation_token
    @plain_secret_key = device.plain_secret_key
    device.save!
  end

  describe "create" do
    it "creates" do
      post :create, body: "Some failure", params: { device_id: device.uuid, key: @plain_secret_key }
      expect(DeviceLog.count).to eq(1)
    end

    it "returns forbidden if wrong key" do
      post :create, body: "Some failure", params: { device_id: device.uuid, key: "#{@plain_secret_key}..." }
      expect(response).to be_forbidden
    end
  end
end
