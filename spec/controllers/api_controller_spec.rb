require 'spec_helper'

describe ApiController do
  let(:institution) {Institution.create name: "baz"}
  let!(:device) {Device.create! name: "foo", institution: institution}
  let(:data) {Oj.dump event: "positive"}

  it "should create an event in the database" do
    conn = post(:create, data, device_uuid: device.secret_key, format: :json)
    conn.status.should eq(200)

    event = Event.first
    event.device_id.should eq(device.id)
    event.raw_data.should_not eq(data)
    event.decrypt.raw_data.should eq(data)
  end
end
