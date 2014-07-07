require 'spec_helper'

describe ApiController do
  let(:device) {Device.make}
  let(:institution) {device.institution}
  let(:data) {Oj.dump results: [result: :positive]}

  def all_elasticsearch_events
    client = Elasticsearch::Client.new log: true
    client.indices.refresh index: institution.elasticsearch_index_name
    client.search(index: institution.elasticsearch_index_name)["hits"]["hits"]
  end

  def get_updates(options)
    client = Elasticsearch::Client.new log: true
    client.indices.refresh index: institution.elasticsearch_index_name
    response = get :events, options
    response.status.should eq(200)
    Oj.load response.body
  end

  context "Creation" do
    it "should create event in the database" do
      response = post :create, data, device_uuid: device.secret_key
      response.status.should eq(200)

      event = Event.first
      event.device_id.should eq(device.id)
      event.raw_data.should_not eq(data)
      event.decrypt.raw_data.should eq(data)
    end

    it "should create event in elasticsearch" do
      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["results"].first["result"].should eq("positive")
      event["created_at"].should_not eq(nil)
      event["device_uuid"].should eq(device.secret_key)
      Event.first.uuid.should eq(event["uuid"])
    end

    it "should override event if event_id is the same" do
      post :create, Oj.dump(event_id: "1234", age: 20), device_uuid: device.secret_key

      event = Event.first
      event.event_id.should eq("1234")

      post :create, Oj.dump(event_id: "1234", age: 30, patient_id: 20), device_uuid: device.secret_key

      Event.count.should eq(1)
      event = Event.first.decrypt
      raw_data = Oj.load event.raw_data
      raw_data["age"].should eq(30)
      event.sensitive_data[:patient_id].should eq(20)

      events = all_elasticsearch_events
      events.size.should eq(1)
      event = events.first
      event["_source"]["event_id"].should eq("1234")
      event["_id"].should eq("#{device.secret_key}_1234")
      event["_source"]["age"].should eq(30)

      post :create, Oj.dump(event_id: "1234", age: 20, patient_id: 22), device_uuid: Device.make(institution: institution).secret_key

      Event.count.should eq(2)
      events = all_elasticsearch_events
      events.size.should eq(2)
    end
  end

  context "Manifest" do
    it "shouldn't store sensitive data in elasticsearch" do
      post :create, Oj.dump(results:[result: :positive], patient_id: 1234), device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["results"].first["result"].should eq("positive")
      event["created_at"].should_not eq(nil)
      event["patient_id"].should eq(nil)
    end

    it "applies an existing manifest" do
      Manifest.create definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1
        },
        "field_mapping" : [{
            "target_field" : "assay_name",
            "selector" : "assay.name",
            "type" : "core"
          }]
      }}
      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["assay_name"].should eq("GX4002")
      event["created_at"].should_not eq(nil)
      event["patient_id"].should be(nil)
    end

    it "stores pii according to manifest" do
      Manifest.create definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1
        },
        "field_mapping" : [
          {
            "target_field": "assay_name",
            "selector" : "assay.name",
            "type" : "core"
          },
          {
            "target_field": "foo",
            "selector" : "patient_id",
            "type" : "custom",
            "pii": true
          }
        ]
      }}

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["assay_name"].should eq("GX4002")
      event["patient_id"].should eq(nil)
      event["foo"].should be(nil)

      event = Event.first
      raw_data = event.sensitive_data
      event.decrypt.sensitive_data.should_not eq(raw_data)
      event.sensitive_data["patient_id"].should be(nil)
      event.sensitive_data["foo"].should eq(1234)
      event.sensitive_data[:foo].should eq(1234)
    end

    it "uses the last version of the manifest" do
      Manifest.create definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1
        },
        "field_mapping" : [
          {
            "target_field": "foo",
            "selector" : "assay.name",
            "type" : "core"
          }
        ]
      }}

      Manifest.create definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 2
        },
        "field_mapping" : [
          {
            "target_field": "assay_name",
            "selector" : "assay.name",
            "type" : "core"
          }
        ]
      }}

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["foo"].should be(nil)
      event["assay_name"].should eq("GX4002")
    end

    it "stores custom fields according to the manifest" do
      Manifest.create definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 2
        },
        "field_mapping" : [
          {
            "target_field": "foo",
            "selector" : "some_field",
            "type" : "custom",
            "pii": false,
            "indexed": false
          }
        ]
      }}

      post :create, Oj.dump(some_field: 1234), device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["foo"].should be(nil)

      event = Event.first.decrypt
      event.sensitive_data["some_field"].should be(nil)
      event.sensitive_data["foo"].should be(nil)
      event.custom_fields[:foo].should eq(1234)
      event.custom_fields["foo"].should eq(1234)
    end
  end

  context "locations" do
    let(:root_location) {Location.make}
    let(:parent_location) {Location.make parent: root_location}
    let(:leaf_location1) {Location.make parent: parent_location}
    let(:leaf_location2) {Location.make parent: parent_location}
    let(:upper_leaf_location) {Location.make parent: root_location}
    let(:laboratory1) {Laboratory.make institution: institution, location: leaf_location1}
    let(:laboratory2) {Laboratory.make institution: institution, location: leaf_location2}
    let(:laboratory3) {Laboratory.make institution: institution, location: upper_leaf_location}

    it "should store the location id when the device is registered in only one laboratory" do
      device.laboratories = [laboratory1]
      device.save!
      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["location_id"].should eq(leaf_location1.id)
      event["laboratory_id"].should eq(laboratory1.id)
      event["parent_locations"].sort.should eq([leaf_location1.id, parent_location.id, root_location.id].sort)
    end

    it "should store the parent location id when the device is registered more than one laboratory" do
      device.laboratories = [laboratory2, laboratory3]
      device.save!

      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["location_id"].should eq(root_location.id)
      event["laboratory_id"].should be(nil)
      event["parent_locations"].should eq([root_location.id])
    end

    it "should store the parent location id when the device is registered more than one laboratory with another tree order" do
      device.laboratories = [laboratory3, laboratory2]
      device.save!

      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["location_id"].should eq(root_location.id)
      event["laboratory_id"].should be(nil)
      event["parent_locations"].should eq([root_location.id])
    end

    it "should store nil if no location was found" do
      device.laboratories = []
      device.save!

      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["location_id"].should be(nil)
      event["laboratory_id"].should be(nil)
      event["parent_locations"].should eq([])
    end
  end

  context "Query" do
    context "Filter" do
      it "should check for new events since a date" do
        Timecop.freeze(Time.utc(2013, 1, 1, 12, 0, 0))

        post :create, data, device_uuid: device.secret_key

        response = get_updates(since: Time.utc(2013, 1, 1, 12, 0, 0).utc.iso8601).first
        response["results"].first["result"].should eq("positive")

        Timecop.freeze(Time.utc(2013, 1, 2, 12, 0, 0))

        post :create, (Oj.dump results:[result: :negative]), device_uuid: device.secret_key

        response = get_updates(since: Time.utc(2013, 1, 2, 12, 0, 0).utc.iso8601).first
        response["results"].first["result"].should eq("negative")

        results = get_updates(since: Time.utc(2013, 1, 1, 12, 0, 0).utc.iso8601)
        results.first["results"].first["result"].should eq("positive")
        results.last["results"].first["result"].should eq("negative")

        get_updates(since: Time.utc(2013, 1, 3, 12, 0, 0).utc.iso8601).should be_empty
      end
    end
  end
end
