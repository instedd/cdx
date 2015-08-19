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
    expect(Manifest.count).to eq(1)
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
      expect(response.keys).to match_array(["device", "encounter", "institution", "laboratory", "location", "patient", "sample", "test"])
      expect(response["device"].keys).to match_array(["uuid", "name", "lab_user", "serial_number"])
      expect(response["institution"].keys).to match_array(["uuid", "name"])
      expect(response["laboratory"].keys).to match_array(["uuid", "name"])
      expect(response["location"].keys).to match_array(["id", "parents", "admin_levels", "lat", "lng"])
      expect(response["patient"].keys).to match_array(["gender"])
      expect(response["sample"].keys).to match_array(["uuid", "id", "type", "collection_date"])
      expect(response["test"].keys).to match_array(["id", "uuid", "start_time", "end_time", "reported_time", "updated_time", "error_code", "error_description", "patient_age", "name", "status", "assays", "quantitative_result", "type"])
      expect(response["test"]["assays"].keys).to match_array(%w(condition name result))
      expect(response["institution"]["name"]).to eq(institution.name)
      expect(response["laboratory"]["name"]).to eq(laboratory.name)
      expect(response["device"]["name"]).to eq(device.name)
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

    expect(TestResult.count).to eq(1)
  end
end
