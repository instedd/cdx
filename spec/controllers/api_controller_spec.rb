require 'spec_helper'

describe ApiController do
  let(:institution) {Institution.create name: "baz"}
  let!(:device) {Device.create! name: "foo", institution: institution}
  let(:data) {Oj.dump event: "positive"}

  def get_all_elasticsearch_events
    client = Elasticsearch::Client.new log: true
    client.indices.refresh index: institution.elasticsearch_index_name
    client.search index: institution.elasticsearch_index_name
  end

  it "should create event in the database" do
    conn = post :create, data, device_uuid: device.secret_key
    conn.status.should eq(200)

    event = Event.first
    event.device_id.should eq(device.id)
    event.raw_data.should_not eq(data)
    event.decrypt.raw_data.should eq(data)
  end

  it "should create event in elasticsearch" do
    conn = post :create, data, device_uuid: device.secret_key

    event = get_all_elasticsearch_events["hits"]["hits"].first["_source"]
    event["event"].should eq("positive")
    event["created_at"].should_not eq(nil)
    event["device_uuid"].should eq(device.secret_key)
  end
end
