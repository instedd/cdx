require 'spec_helper'

describe Subscriber, elasticsearch: true do

  let(:model){DeviceModel.make}
  let(:device){Device.make device_model: model}
  let(:device_message){DeviceMessage.make(device: device)}
  let(:institution){device.institution}
  let(:laboratory){device.laboratories.first}

  let!(:filter) { Filter.make query: {"condition" => "mtb", "laboratory" => laboratory.id.to_s}, user: institution.user}
  let!(:manifest) {
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "#{Manifest::CURRENT_VERSION}",
          "device_models": "#{model.name}",
          "conditions": ["MTB"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "test.assays[*].result" : {"lookup" : "result"},
          "test.assays[*].name" : {"lookup" : "condition"},
          "patient.gender" : {"lookup" : "patient_gender"}
        }
      }
    }
  }

  it "should have a manifest" do
    Manifest.count.should eq(1)
  end

  it "generates a correct filter_test GET query with specified fields" do
    fields = ["test.assays.name", "test.assays.result", "patient.gender"]
    url = "http://subscriber/cdp_trigger"
    subscriber = Subscriber.make fields: fields, url: url, filter: filter, verb: 'GET'
    callback_query = "http://subscriber/cdp_trigger?patient%5Bgender%5D=male&test%5Bassays%5D%5Bname%5D=mtb&test%5Bassays%5D%5Bresult%5D=positive"
    callback_request = stub_request(:get, callback_query).to_return(:status => 200, :body => "", :headers => {})

    submit_test

    Subscriber.notify_all

    assert_requested(callback_request)
  end

  it "generates a correct filter_test POST query with specified fields" do
    fields = ["test.asssays.name", "test.assays.result", "patient.gender"]
    url = "http://subscriber/cdp_trigger?token=48"
    subscriber = Subscriber.make fields: fields, url: url, filter: filter, verb: 'POST'
    callback_request = stub_request(:post, url).
         with(:body => '{"test":{"assays":{"result":"positive"}},"patient":{"gender":"male"}}').
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
      response.keys.should =~ ["device", "encounter", "institution", "laboratory", "location", "patient", "sample", "test"]
      response["device"].keys.should =~ ["uuid", "name", "lab_user", "serial_number"]
      response["institution"].keys.should =~ ["id", "name"]
      response["laboratory"].keys.should =~ ["id", "name"]
      response["location"].keys.should =~ ["id", "parents", "admin_levels", "lat", "lng"]
      response["patient"].keys.should =~ ["gender"]
      response["sample"].keys.should =~ ["uuid", "id", "type", "collection_date"]
      response["test"].keys.should =~ ["id", "uuid", "start_time", "end_time", "reported_time", "updated_time", "error_code", "error_description", "patient_age", "name", "status", "assays", "quantitative_result", "type"]
      response["test"]["assays"].keys.should =~ %w(condition name result)
      response["institution"]["name"].should eq(institution.name)
      response["laboratory"]["name"].should eq(laboratory.name)
      response["device"]["name"].should eq(device.name)
    end
  end

  def submit_test
    patient = Patient.make(
      core_fields: {"gender" => "male"}
    )

    sample = Sample.make patient: patient

    TestResult.create_and_index(
      patient: patient, sample: sample,
      core_fields: {"assays" => ["result" => "positive", "name" => "mtb"]},
      device_messages: [device_message]
    )

    refresh_index

    TestResult.count.should eq(1)
  end
end
