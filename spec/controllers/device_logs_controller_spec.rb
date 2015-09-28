require 'spec_helper'
require 'policy_spec_helper'

describe DeviceLogsController do
  let(:institution) {Institution.make}
  let(:device) { Device.make institution: institution}

  it "creates" do
    device.set_key_for_activation_token
    plain_secret_key = device.plain_secret_key
    device.save!

    post :create, "Some failure", device_id: device.uuid, key: plain_secret_key
    expect(DeviceLog.count).to eq(1)
  end
end
