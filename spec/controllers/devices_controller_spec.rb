require 'spec_helper'

describe DevicesController do
  let(:institution) {Institution.make}
  let(:user) {institution.user}
  let(:device_model) {DeviceModel.make}

  before(:each) {sign_in user}

  context "Update" do
    let(:device) {Device.make institution: institution}

    it "device is successfully updated if name is provided" do
      d = Device.find(device.id)
      d.name.should_not eq("New device")

      patch :update, {"institution_id" => institution.id, "id" => device.id, "device" => {"name" => "New device"}}

      d = Device.find(device.id)
      d.name.should eq("New device")
    end

    it "device is not updated if name is not provided" do
      d = Device.find(device.id)
      d.name.should eq(device.name)

      patch :update, {"institution_id" => institution.id, "id" => device.id, "device" => {"name" => ""}}

      d = Device.find(device.id)
      d.name.should eq(device.name)
    end

  end

end
