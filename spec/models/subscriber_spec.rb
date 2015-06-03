require 'spec_helper'

describe Subscriber, elasticsearch: true do

  let(:model){DeviceModel.make}
  let(:device){Device.make device_model: model}
  let(:device_event){DeviceEvent.make(device: device)}
  let(:institution){device.institution}
  let(:laboratory){device.laboratories.first}

  let!(:filter) { Filter.make query: {"condition" => "mtb", "laboratory" => laboratory.id.to_s} }
  let!(:manifest) {
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1.1.0",
          "device_models": "#{model.name}",
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "test" : [
            {
              "target_field" : "results[*].result",
              "source" : {"lookup" : "result"},
              "core" : true,
              "type" : "enum",
              "options" : ["positive","negative"]
            },
            {
              "target_field" : "results[*].condition",
              "source" : {"lookup" : "condition"},
              "core" : true,
              "type" : "enum",
              "options" : ["mtb","flu_a"]
            }
          ],
          "patient" : [
            {
              "target_field" : "patient_name",
              "source" : {"lookup" : "patient_name"},
              "core" : true,
              "type" : "string"
            }
          ]
        }
      }
    }
  }

  it "should have a manifest" do
    Manifest.count.should eq(1)
  end

  it "generates a correct filter_test GET query with specified fields" do
    fields = ["condition", "result", "patient_name"]
    url = "http://subscriber/cdp_trigger"
    subscriber = Subscriber.make fields: fields, url: url, filter: filter, verb: 'GET'
    callback_query = "http://subscriber/cdp_trigger?condition=mtb&patient_name=jdoe&result=positive"
    callback_request = stub_request(:get, callback_query).to_return(:status => 200, :body => "", :headers => {})

    submit_test

    Subscriber.notify_all

    assert_requested(callback_request)
  end

  it "generates a correct filter_test POST query with specified fields" do
    fields = ["condition", "result", "patient_name"]
    url = "http://subscriber/cdp_trigger?token=48"
    subscriber = Subscriber.make fields: fields, url: url, filter: filter, verb: 'POST'
    callback_request = stub_request(:post, url).
         with(:body => "{\"condition\":\"mtb\",\"result\":\"positive\",\"patient_name\":\"jdoe\"}").
         to_return(:status => 200, :body => "", :headers => {})

    submit_test

    Subscriber.notify_all

    assert_requested(callback_request)
  end

  it "generates a correct filter_test POST query with all fields" do
    url = "http://subscriber/cdp_trigger?token=48"
    subscriber = Subscriber.make fields: [], url: url, filter: filter, verb: 'POST'
    callback_request = stub_request(:post, url).to_return(:status => 200, :body => "", :headers => {})

    submit_test

    Subscriber.notify_all

    assert_requested(:post, url) do |req|
      response = JSON.parse(req.body)
      response.keys.should =~ ["age","assay_name","condition","created_at","device_serial_number","device_uuid", "device_name", "error_code","error_description","ethnicity","test_id","gender","institution_id", "institution_name","laboratory_id", "laboratory_name","location","race","race_ethnicity","result","sample_collection_date","start_time","status","system_user","test_type","updated_at","uuid", "sample_type", "sample_uuid", "sample_id", "location_coords"]
      response["institution_name"].should eq(institution.name)
      response["laboratory_name"].should eq(laboratory.name)
      response["device_name"].should eq(device.name)
    end
  end

  def submit_test
    TestResult.create_and_index({ results: [result: "positive", condition: "mtb"], patient_name: "jdoe" }, {device_events: [device_event]})
    client = Cdx::Api.client
    client.indices.refresh index: institution.elasticsearch_index_name

    TestResult.count.should eq(1)
  end
end
