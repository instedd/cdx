require 'spec_helper'
require 'policy_spec_helper'

describe Subscriber, elasticsearch: true do

  let(:model){DeviceModel.make}
  let(:device){Device.make device_model: model}
  let(:device_message){DeviceMessage.make(device: device)}
  let(:institution){device.institution}
  let(:site){device.site}

  let!(:filter) { Filter.make query: {"test.assays.condition" => "mtb", "site.uuid" => site.uuid}, user: institution.user}
  let!(:manifest) {
    manifest = Manifest.create! device_model: model, definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "#{Manifest::CURRENT_VERSION}",
          "conditions": ["mtb"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "test.assays.result" : {"lookup" : "result"},
          "test.assays.name" : {"lookup" : "condition"},
          "patient.gender" : {"lookup" : "patient_gender"}
        }
      }
    }
  }

  it "should have a manifest" do
    expect(Manifest.count).to eq(1)
  end

  it "generates a correct filter_test GET query with specified fields" do
    fields = ["test.assays", "patient.gender"]
    url = "http://subscriber/cdp_trigger"
    subscriber = Subscriber.make fields: fields, url: url, filter: filter, verb: 'GET'
    callback_query = "http://subscriber/cdp_trigger?patient%5Bgender%5D=male&test%5Bassays%5D%5B0%5D%5Bcondition%5D=mtb&test%5Bassays%5D%5B1%5D%5Bname%5D=mtb&test%5Bassays%5D%5B2%5D%5Bresult%5D=positive"
    callback_request = stub_request(:get, callback_query).to_return(status: 200, body: "", headers: {})

    submit_test

    assert_requested(callback_request)
  end

  it "generates a correct filter_test POST query with specified fields" do
    fields = ["test.assays", "patient.gender"]
    url = "http://subscriber/cdp_trigger?token=48"
    subscriber = Subscriber.make fields: fields, url: url, filter: filter, verb: 'POST'
    callback_request = stub_request(:post, url)
      .with(body: {
        test: { assays: [{result:"positive", condition:"mtb", name:"mtb"}] },
        patient: {gender: "male" }
      })
      .to_return(status: 200, body: "", headers: {})

    submit_test

    assert_requested(callback_request)
  end

  it "generates a correct filter_test POST query with all fields" do
    url = "http://subscriber/cdp_trigger?token=48"
    subscriber = Subscriber.make fields: [], url: url, filter: filter, verb: 'POST'
    callback_request = stub_request(:post, url).to_return(:status => 200, :body => "", :headers => {})

    submit_test

    assert_requested(:post, url) do |req|
      response = JSON.parse(req.body)
      expect(response.keys).to match_array(["device", "encounter", "institution", "site", "location", "patient", "sample", "test"])
      expect(response["device"].keys).to match_array(["model", "uuid", "name", "serial_number"])
      expect(response["institution"].keys).to match_array(["uuid", "name"])
      expect(response["site"].keys).to match_array(["uuid", "name", "path"])
      expect(response["location"].keys).to match_array(["id", "parents", "admin_levels", "lat", "lng"])
      expect(response["patient"].keys).to match_array(["gender"])
      expect(response["sample"].keys).to match_array(["uuid", "id", "type", "collection_date"])
      expect(response["test"].keys).to match_array(["id", "uuid", "start_time", "end_time", "reported_time", "updated_time", "error_code", "error_description", "patient_age", "name", "status", "assays", "type", "site_user"])
      expect(response["institution"]["name"]).to eq(institution.name)
      expect(response["site"]["name"]).to eq(site.name)
      expect(response["device"]["name"]).to eq(device.name)
    end
  end

  it "creates percolator for each subscriber" do
    subscriber = Subscriber.make filter: filter, user: institution.user
    percolator = Cdx::Api.client.get index: Cdx::Api.index_name_pattern, type: '.percolator', id: subscriber.id
    expect(percolator["_source"]).to eq({query: filter.create_query.elasticsearch_query, type: 'test'}.with_indifferent_access)
  end

  it "updates percolator when the filter changes" do
    subscriber = Subscriber.make filter: filter, user: institution.user
    filter.update_attributes! query: {"test.assays.condition" => "mtb"}
    percolator = Cdx::Api.client.get index: Cdx::Api.index_name_pattern, type: '.percolator', id: subscriber.id
    expect(percolator["_source"]).to eq({query: filter.create_query.elasticsearch_query, type: 'test'}.with_indifferent_access)
  end

  it "updates percolator when policies are changed" do
    user2 = User.make
    filter2 = Filter.make query: {"test.assays.condition" => "mtb", "site.uuid" => site.uuid}, user: user2
    url = "http://subscriber/cdp_trigger?token=48"
    subscriber = Subscriber.make filter: filter2, user: user2, fields: [], url: url, verb: 'POST'
    callback_request = stub_request(:post, url).to_return(:status => 200, :body => "", :headers => {})
    grant(institution.user, user2, "testResult?device=#{device.id}", Policy::Actions::QUERY_TEST)

    submit_test

    assert_requested(callback_request)
  end

  it "deletes percolator when the subscriber is deleted" do
    subscriber = Subscriber.make filter: filter, user: institution.user
    subscriber.destroy
    refresh_index
    result = Cdx::Api.client.search index: Cdx::Api.index_name_pattern, type: '.percolator'
    expect(result["hits"]["total"]).to eq(0)
  end

  def submit_test
    patient = Patient.make(
      core_fields: {"gender" => "male"}
    )

    sample = Sample.make patient: patient
    sample_identifier = SampleIdentifier.make sample: sample

    TestResult.create_and_index(
      patient: patient, sample_identifier: sample_identifier,
      core_fields: {"assays" => ["result" => "positive", "condition" => "mtb", "name" => "mtb"]},
      device_messages: [device_message]
    )

    expect(TestResult.count).to eq(1)
  end
end
