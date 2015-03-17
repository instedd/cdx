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
          "event" : [
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

  it "generates a correct filter_event GET query with specified fields" do
    fields = ["condition", "result", "patient_name"]
    url = "http://subscriber/cdp_trigger"
    subscriber = Subscriber.make fields: fields, url: url, filter: filter, verb: 'GET'
    callback_query = "http://subscriber/cdp_trigger?condition=mtb&patient_name=jdoe&result=positive"
    callback_request = stub_request(:get, callback_query).to_return(:status => 200, :body => "", :headers => {})

    submit_event

    Subscriber.notify_all

    assert_requested(callback_request)
  end

  it "generates a correct filter_event POST query with specified fields" do
    fields = ["condition", "result", "patient_name"]
    url = "http://subscriber/cdp_trigger?token=48"
    subscriber = Subscriber.make fields: fields, url: url, filter: filter, verb: 'POST'
    callback_request = stub_request(:post, url).
         with(:body => "{\"condition\":\"mtb\",\"result\":\"positive\",\"patient_name\":\"jdoe\"}").
         to_return(:status => 200, :body => "", :headers => {})

    submit_event

    Subscriber.notify_all

    assert_requested(callback_request)
  end

  it "generates a correct filter_event POST query with all fields" do
    url = "http://subscriber/cdp_trigger?token=48"
    subscriber = Subscriber.make fields: [], url: url, filter: filter, verb: 'POST'
    callback_request = stub_request(:post, url).to_return(:status => 200, :body => "", :headers => {})

    submit_event

    Subscriber.notify_all

    assert_requested(:post, url) do |req|
      JSON.parse(req.body).keys.should =~ ["age","assay_name","condition","created_at","device_serial_number","device_uuid","error_code","error_description","ethnicity","event_id","gender","institution_id","laboratory_id","location","race","race_ethnicity","result","start_time","status","system_user","test_type","updated_at","uuid", "sample_type", "sample_uuid", "sample_id"]
    end
  end

  def submit_event
    Event.create_and_index({ results: [result: "positive", condition: "mtb"], patient_name: "jdoe" }, {device_events: [device_event]})
    client = Cdx::Api.client
    client.indices.refresh index: institution.elasticsearch_index_name

    Event.count.should eq(1)
  end
end
