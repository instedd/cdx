require 'spec_helper'
require 'policy_spec_helper'

describe TestResultQuery, elasticsearch: true do

  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:user_device) {Device.make institution_id: institution.id}
  let(:second_user_device) {Device.make institution_id: institution.id}
  let(:second_institution) {Institution.make user_id: user.id}
  let(:third_user_device) {Device.make institution_id: second_institution.id}
  let(:non_user_device) {Device.make}
  let(:second_user) {User.make}

  it "applies institution policy" do
    TestResult.create_and_index(
      indexed_fields: {"test" => {"results" =>["condition" => "mtb", "result" => :positive]}},
      device_messages:[DeviceMessage.make(device: user_device)]
    )
    TestResult.create_and_index(
      indexed_fields: {"test" => {"results" =>["condition" => "mtb", "result" => :negative]}},
      device_messages:[DeviceMessage.make(device: non_user_device)]
    )
    client = Cdx::Api.client
    client.indices.refresh index: institution.elasticsearch_index_name
    client.indices.refresh index: non_user_device.institution.elasticsearch_index_name

    query = TestResultQuery.new({condition: 'mtb'}, user)

    query.result['total_count'].should eq(1)
    query.result['tests'].first['test']['results'].first['result'].should eq('positive')
  end

  it "delegates institution policy" do
    TestResult.create_and_index(
      indexed_fields: {"test" => {"results" =>["condition" => "mtb", "result" => :positive]}},
      device_messages:[DeviceMessage.make(device: user_device)]
    )
    TestResult.create_and_index(
      indexed_fields: {"test" => {"results" =>["condition" => "mtb", "result" => :negative]}},
      device_messages:[DeviceMessage.make(device: third_user_device)]
    )
    client = Cdx::Api.client
    client.indices.refresh index: institution.elasticsearch_index_name

    grant(user, second_user, institution, QUERY_TEST)

    query = TestResultQuery.new({condition: 'mtb'}, second_user)

    query.result['total_count'].should eq(1)
    query.result['tests'].first['test']['results'].first['result'].should eq('positive')
  end

  it "doesn't fails if no device is indexed for the institution yet" do
    institution
    client = Cdx::Api.client
    client.indices.refresh index: institution.elasticsearch_index_name

    query = TestResultQuery.new({condition: 'mtb'}, user)

    query.result['total_count'].should eq(0)
    query.result['tests'].should eq([])
  end

  it "should not access any test if has no policy" do
    TestResult.create_and_index(
      indexed_fields: {"test" => {"results" =>["condition" => "mtb", "result" => :positive]}},
      device_messages:[DeviceMessage.make(device: user_device)]
    )
    client = Cdx::Api.client
    client.indices.refresh index: institution.elasticsearch_index_name

    query = TestResultQuery.new({condition: 'mtb'}, User.new)

    query.result['total_count'].should eq(0)
    query.result['tests'].should eq([])
  end
end
