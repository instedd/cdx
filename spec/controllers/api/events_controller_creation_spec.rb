require 'spec_helper'

describe Api::EventsController do
  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  let(:data)  {Oj.dump results: [result: :positive]}
  let(:datas) {Oj.dump [{results: [result: :positive]}, {results: [result: :negative]}]}
  before(:each) {sign_in user}

  def get_updates(options, body="")
    fresh_client_for institution.elasticsearch_index_name
    response = get :index, body, options.merge(format: 'json')
    response.status.should eq(200)
    Oj.load(response.body)["events"]
  end

  context "Creation" do

    it "should create event in the database" do
      response = post :create, data, device_id: device.secret_key
      response.status.should eq(200)

      event = DeviceEvent.first
      event.device_id.should eq(device.id)
      event.raw_data.should_not eq(data)
      event.plain_text_data.should eq(data)
    end

    it "should create event in elasticsearch" do
      post :create, data, device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["results"].first["result"].should eq("positive")
      event["created_at"].should_not eq(nil)
      event["device_uuid"].should eq(device.secret_key)
      Event.first.uuid.should eq(event["uuid"])
    end

    it "should create multiple events in the database" do
      response = post :create, datas, device_id: device.secret_key
      response.status.should eq(200)

      event = DeviceEvent.first
      event.device_id.should eq(device.id)
      event.raw_data.should_not eq(datas)
      event.plain_text_data.should eq(datas)

      Event.count.should eq(2)
    end

    it "should create multiple events in elasticsearch" do
      post :create, datas, device_id: device.secret_key

      events = all_elasticsearch_events_for(institution)
      events.count.should eq(2)

      events.first["_source"]["results"].first["result"].should eq("positive")
      events.last["_source"]["results"].first["result"].should eq("negative")

      Event.first.uuid.should eq(events.first["_source"]["uuid"])
      Event.last.uuid.should eq(events.last["_source"]["uuid"])
    end

    it "should store institution_id in elasticsearch" do
      post :create, data, device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["institution_id"].should eq(device.institution_id)
    end

    it "should override event if event_id is the same" do
      post :create, Oj.dump(event_id: "1234", age: 20), device_id: device.secret_key

      Event.count.should eq(1)
      event = Event.first
      event.event_id.should eq("1234")

      Oj.load(DeviceEvent.first.plain_text_data)["age"].should eq(20)

      events = all_elasticsearch_events_for(institution)
      events.size.should eq(1)
      event = events.first
      event["_source"]["event_id"].should eq("1234")
      event["_id"].should eq("#{device.secret_key}_1234")
      event["_source"]["age"].should eq(20)

      post :create, Oj.dump(event_id: "1234", age: 30), device_id: device.secret_key

      Event.count.should eq(1)
      event = Event.first
      event.event_id.should eq("1234")

      DeviceEvent.count.should eq(2)
      Oj.load(DeviceEvent.last.plain_text_data)["age"].should eq(30)

      events = all_elasticsearch_events_for(institution)
      events.size.should eq(1)
      event = events.first
      event["_source"]["event_id"].should eq("1234")
      event["_id"].should eq("#{device.secret_key}_1234")
      event["_source"]["age"].should eq(30)

      post :create, Oj.dump(event_id: "1234", age: 20), device_id: Device.make(institution: institution).secret_key

      Event.count.should eq(2)
      events = all_elasticsearch_events_for(institution)
      events.size.should eq(2)
    end

    it "should generate a start_time date if it's not provided" do
      post :create, data, device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["start_time"].should eq(event["created_at"])
    end

    it "should create a sample" do
      response = post :create, data, device_id: device.secret_key
      response.status.should eq(200)

      event = Event.first
      sample = Sample.first
      event.sample.should eq(sample)
      sample.sample_uid_hash.should be(nil)
      sample.uuid.should_not be(nil)
    end
  end

  context "Manifest" do
    it "shouldn't store sensitive data in elasticsearch" do
      post :create, Oj.dump(results:[result: :positive], patient_id: 1234), device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["results"].first["result"].should eq("positive")
      event["created_at"].should_not eq(nil)
      event["patient_id"].should eq(nil)
    end

    it "applies an existing manifest" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "1.1.0",
          "source" : {"type" : "json"}
        },
        "field_mapping" : { "event" : [{
          "target_field" : "assay_name",
          "source" : {"lookup" : "assay.name"},
          "type" : "string",
          "core" : true
        }]}
      }}
      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["assay_name"].should eq("GX4002")
      event["created_at"].should_not eq(nil)
      event["patient_id"].should be_nil
    end

    it "stores pii in the event according to manifest" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "1.1.0",
          "source" : {"type" : "json"}
        },
        "field_mapping" : {"event" : [
          {
            "target_field" : "assay_name",
            "source" : {"lookup" : "assay.name"},
            "type" : "string",
            "core" : true
          },
          {
            "target_field" : "foo",
            "source" : {"lookup" : "patient_id"},
            "type" : "integer",
            "pii" : true
          }
        ]}
      }}

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["assay_name"].should eq("GX4002")
      event["patient_id"].should eq(nil)
      event["foo"].should be_nil

      event = Event.first
      raw_data = event.sensitive_data
      event.plain_sensitive_data.should_not eq(raw_data)
      event.plain_sensitive_data["patient_id"].should be_nil
      event.plain_sensitive_data["foo"].should eq(1234)
      event.plain_sensitive_data[:foo].should eq(1234)
    end

    it "merges pii from different tests in the same sample across devices" do
      device2 = Device.make institution_id: institution.id, device_model: device.device_model
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "1.1.0",
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "event" : [
            {
              "target_field" : "assay_name",
              "source" : {"lookup" : "assay.name"},
              "type" : "string",
              "core" : true,
              "indexed" : true
            }
          ],
          "sample" : [
            {
              "target_field" : "sample_uid",
              "source" : {"lookup" : "sample_id"},
              "type" : "string",
              "core" : true,
              "pii" : true
            }
          ],
          "patient" : [
            {
              "target_field" : "patient_id",
              "source" : {"lookup" : "patient_id"},
              "type" : "integer",
              "pii" : true
            },
            {
              "target_field" : "patient_telephone_number",
              "source" : {"lookup" : "patient_telephone_number"},
              "type" : "integer",
              "pii" : true
            }
          ]
        }
      }}

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 3, sample_id: "10"), device_id: device.secret_key
      post :create, Oj.dump(assay: {name: "GX4002"}, patient_telephone_number: 2222222, sample_id: 10), device_id: device2.secret_key

      Event.count.should eq(2)
      Sample.count.should eq(1)

      Event.first.sample.should eq(Sample.first)
      Event.last.sample.should eq(Sample.first)

      sample = Sample.first
      sample.plain_sensitive_data["sample_uid"].should eq(10)
      sample.plain_sensitive_data["patient_id"].should eq(3)
      sample.plain_sensitive_data["patient_telephone_number"].should eq(2222222)
    end

    it "uses the last version of the manifest" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "1.1.0",
          "source" : {"type" : "json"}
        },
        "field_mapping" : { "event" : [
          {
            "target_field" : "foo",
            "source" : {"lookup" : "assay.name"},
            "type" : "string",
            "core" : true
          }
        ]}
      }}

      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 2,
          "api_version" : "1.1.0",
          "source" : {"type" : "json"}
        },
        "field_mapping" : { "event" : [
          {
            "target_field" : "assay_name",
            "source" : {"lookup" : "assay.name"},
            "type" : "string",
            "core" : true
          }
        ]}
      }}

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["foo"].should be_nil
      event["assay_name"].should eq("GX4002")
    end

    it "stores custom fields according to the manifest" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 2,
          "api_version" : "1.1.0",
          "source" : {"type" : "json"}
        },
        "field_mapping" : { "event" : [
          {
            "target_field" : "foo",
            "source" : {"lookup" : "some_field"},
            "type" : "string"
          }
        ]}
      }}

      post :create, Oj.dump(some_field: 1234), device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["foo"].should be_nil

      event = Event.first
      sample = event.sample
      sample.sensitive_data["some_field"].should be_nil
      sample.sensitive_data["foo"].should be_nil
      event.custom_fields[:foo].should eq(1234)
      event.custom_fields["foo"].should eq(1234)
    end

    it "validates the data type" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "api_version" : "1.1.0",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : { "event" : [{
            "target_field" : "error_code",
            "source" : {"lookup" : "error_code"},
            "core" : true,
            "type" : "integer"
          }]}
      }}
      post :create, Oj.dump(error_code: 1234), device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["error_code"].should eq(1234)

      post :create, Oj.dump(error_code: "foo"), device_id: device.secret_key

      response.code.should eq("422")
      Oj.load(response.body)["errors"].should eq("'foo' is not a valid value for 'error_code' (must be an integer)")
    end

    context "csv" do

      let!(:manifest) do Manifest.create! definition: %{
          {
            "metadata" : {
              "version" : "1",
              "api_version" : "1.1.0",
              "device_models" : "#{device.device_model.name}",
              "source" : { "type" : "csv" }
            },
            "field_mapping" : { "event" : [{
                "target_field" : "error_code",
                "source" : {"lookup" : "error_code"},
                "core" : true,
                "type" : "integer"
              },
              {
                "target_field" : "result",
                "source" : {"lookup" : "result"},
                "core" : true,
                "type" : "enum",
                "options" : [
                  "positive",
                  "negative"
                ]
              }
            ]}
          }
        }
      end

      it 'parses a single line csv' do
        csv = %{error_code;result\n0;positive}
        post :create, csv, device_id: device.secret_key

        events = all_elasticsearch_events_for(institution).sort_by { |event| event["_source"]["error_code"] }
        events.count.should eq(1)
        event = events.first["_source"]
        event["error_code"].should eq("0")
        event["result"].should eq("positive")
      end

      it 'parses a multi line csv' do
        csv = %{error_code;result\n0;positive\n1;negative}
        post :create, csv, device_id: device.secret_key

        events = all_elasticsearch_events_for(institution).sort_by { |event| event["_source"]["error_code"] }
        events.count.should eq(2)
        event = events.first["_source"]
        event["error_code"].should eq("0")
        event["result"].should eq("positive")
        event = events.last["_source"]
        event["error_code"].should eq("1")
        event["result"].should eq("negative")
      end
    end

    context "real scenarios" do
      it 'parses genoscan csv' do
        manifest = Manifest.create! definition: IO.read(File.join(Rails.root, 'db', 'seeds', 'manifests', 'genoscan_manifest.json'))
        device = Device.make institution_id: institution.id, device_model: DeviceModel.find_by_name('genoscan')

        data = IO.read(File.join(Rails.root, 'spec', 'support', 'genoscan_sample.csv'))
        post :create, data, device_id: device.secret_key

        events = all_elasticsearch_events_for(device.institution).sort_by { |event| event["_source"]["results"][0]["result"] }
        events.should have(5).items

        event = events.first["_source"]
        event["results"][0]["condition"].should eq("mtb")
        event["results"][0]["result"].should eq("positive")

        event = events.last["_source"]
        event["results"][0]["condition"].should eq("mtb")
        event["results"][0]["result"].should eq("positive_with_rmp_and_inh")

        dbevents = Event.all
        dbevents.should have(5).items
        dbevents.map(&:uuid).should =~ events.map {|e| e['_source']['uuid']}
      end
    end

  end
end
