require 'spec_helper'
require 'policy_spec_helper'

describe DeviceLogsController do
  let(:institution) {Institution.make}
  let(:device) {Device.make institution: institution}

  it "creates" do
    post :create, "Some failure", device_id: device.uuid
    expect(DeviceLog.count).to eq(1)
  end
end
