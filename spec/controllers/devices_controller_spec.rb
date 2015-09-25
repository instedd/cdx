require 'spec_helper'
require 'policy_spec_helper'

describe DevicesController do
  let(:institution) {Institution.make}
  let(:user) {institution.user}
  let(:device_model) {DeviceModel.make}
  let(:device) {Device.make institution: institution}

  before(:each) {sign_in user}

  context "Index" do
    it "should display index when other user grants admin permission" do
      user2 = User.make
      institution2 = Institution.make user: user2
      institution2.devices.make

      grant user2, user, [Institution.resource_name, Device.resource_name], "*"

      get :index, institution_id: institution2.id
    end
  end

  context "Update" do
    it "device is successfully updated if name is provided" do
      d = Device.find(device.id)
      expect(d.name).not_to eq("New device")

      patch :update, {"institution_id" => institution.id, "id" => device.id, "device" => {"name" => "New device"}}

      d = Device.find(device.id)
      expect(d.name).to eq("New device")
    end

    it "device is not updated if name is not provided" do
      d = Device.find(device.id)
      expect(d.name).to eq(device.name)

      patch :update, {"institution_id" => institution.id, "id" => device.id, "device" => {"name" => ""}}

      d = Device.find(device.id)
      expect(d.name).to eq(device.name)
    end
  end

  describe "generate_activation_token" do
    before { post :generate_activation_token, {"institution_id" => device.institution_id, "id" => device.id} }
    let(:token) { ActivationToken.find_by(device_id: device.id)  }

    it { expect(token).not_to be_nil }
    it { expect(token.device).to eq(device) }
    it { expect(token.client_id).to eq(device.uuid) }
    it { expect(token.value).not_to be_nil }
  end
end
