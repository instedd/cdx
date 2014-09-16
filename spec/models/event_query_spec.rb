require 'spec_helper'
require 'policy_spec_helper'

describe EventQuery do
  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:user_device) {Device.make institution_id: institution.id}
  let(:second_user_device) {Device.make institution_id: institution.id}
  let(:second_institution) {Institution.make user_id: user.id}
  let(:third_user_device) {Device.make institution_id: second_institution.id}
  let(:non_user_device) {Device.make}
  let(:second_user) {User.make}

  it "applies institution policy" do
    Event.create_or_update_with user_device, Oj.dump(results:[condition: "mtb", result: :positive])
    Event.create_or_update_with non_user_device, Oj.dump(results:[condition: "mtb", result: :negative])
    client = Cdx::Api.client
    client.indices.refresh index: institution.elasticsearch_index_name
    client.indices.refresh index: non_user_device.institution.elasticsearch_index_name

    query = EventQuery.new({condition: 'mtb'}, user)

    query.result['total_count'].should eq(1)
    query.result['events'].first['results'].first['result'].should eq('positive')
  end

  it "delegates institution policy" do
    Event.create_or_update_with user_device, Oj.dump(results:[condition: "mtb", result: :positive])
    Event.create_or_update_with third_user_device, Oj.dump(results:[condition: "mtb", result: :negative])
    client = Cdx::Api.client
    client.indices.refresh index: institution.elasticsearch_index_name

    grant(user, second_user, institution, QUERY_EVENT)

    query = EventQuery.new({condition: 'mtb'}, second_user)

    query.result['total_count'].should eq(1)
    query.result['events'].first['results'].first['result'].should eq('positive')
  end

  it "doesn't fails if no device is indexed for the institution yet" do
    institution

    query = EventQuery.new({condition: 'mtb'}, user)

    query.result['total_count'].should eq(0)
    query.result['events'].should eq([])
  end

  it "should not access any event if has no policy" do
    Event.create_or_update_with user_device, Oj.dump(results:[condition: "mtb", result: :positive])
    client = Cdx::Api.client
    client.indices.refresh index: institution.elasticsearch_index_name

    query = EventQuery.new({condition: 'mtb'}, User.new)

    query.result['total_count'].should eq(0)
    query.result['events'].should eq([])
  end
end
