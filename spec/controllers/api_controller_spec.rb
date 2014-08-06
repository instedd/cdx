require 'spec_helper'

describe ApiController do
  let(:user) {User.make}
  let(:device) {Device.make}
  let(:institution) {device.institution}
  let(:data) {Oj.dump results: [result: :positive]}
  before(:each) {sign_in user}

  def all_elasticsearch_events
    client = fresh_client_for institution.elasticsearch_index_name
    client.search(index: institution.elasticsearch_index_name)["hits"]["hits"]
  end

  def get_updates(options, body="")
    fresh_client_for institution.elasticsearch_index_name
    response = get :events, body, options.merge(format: 'json')
    response.status.should eq(200)
    Oj.load(response.body)["events"]
  end

  def fresh_client_for index_name
    client = Cdx::Api.client
    client.indices.refresh index: index_name
    client
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

    it "should store institution_id in elasticsearch" do
      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["institution_id"].should eq(device.institution_id)
    end

    it "should override event if event_id is the same" do
      post :create, Oj.dump(event_id: "1234", age: 20, patient_name: 'john doe'), device_uuid: device.secret_key

      event = Event.first.decrypt
      event.event_id.should eq("1234")
      raw_data = Oj.load event.raw_data
      raw_data["age"].should eq(20)
      event.sensitive_data[:patient_id].should be(nil)
      event.sensitive_data[:patient_name].should eq('john doe')

      post :create, Oj.dump(event_id: "1234", age: 30, patient_id: 20, patient_name: 'jane doe'), device_uuid: device.secret_key

      Event.count.should eq(1)
      event = Event.first.decrypt
      raw_data = Oj.load event.raw_data
      raw_data["age"].should eq(30)
      event.sensitive_data[:patient_id].should eq(20)
      event.sensitive_data[:patient_name].should eq('jane doe')

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

  context "Locations" do
    let(:root_location) {Location.create_default}
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
      device.laboratories = [laboratory1, laboratory2]
      device.save!

      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["location_id"].should eq(parent_location.id)
      event["laboratory_id"].should be(nil)
      event["parent_locations"].should eq([root_location.id, parent_location.id].sort)
    end

    it "should store the root location id when the device is registered more than one laboratory" do
      device.laboratories = [laboratory2, laboratory3]
      device.save!

      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["location_id"].should eq(root_location.id)
      event["laboratory_id"].should be(nil)
      event["parent_locations"].should eq([root_location.id])
    end

    it "should store the root location id when the device is registered more than one laboratory with another tree order" do
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

    it "filters by location" do
      device1 = Device.make institution: institution, laboratories: [laboratory1]
      device2 = Device.make institution: institution, laboratories: [laboratory2]
      device3 = Device.make institution: institution, laboratories: [laboratory3]
      post :create, (Oj.dump results:[result: "negative"]), device_uuid: device1.secret_key
      post :create, (Oj.dump results:[result: "positive"]), device_uuid: device2.secret_key
      post :create, (Oj.dump results:[result: "positive with riff"]), device_uuid: device3.secret_key

      response = get_updates(location: leaf_location1.id)

      response.first["results"].first["result"].should eq("negative")

      response = get_updates(location: leaf_location2.id)

      response.first["results"].first["result"].should eq("positive")

      response = get_updates(location: parent_location.id).sort_by do |event|
        event["results"].first["result"]
      end

      response.size.should be(2)
      response[0]["results"].first["result"].should eq("negative")
      response[1]["results"].first["result"].should eq("positive")

      response = get_updates(location: root_location.id).sort_by do |event|
        event["results"].first["result"]
      end

      response.size.should be(3)
      response[0]["results"].first["result"].should eq("negative")
      response[1]["results"].first["result"].should eq("positive")
      response[2]["results"].first["result"].should eq("positive with riff")
    end

    it "groups by administrative level" do
      device1 = Device.make institution: institution, laboratories: [laboratory1]
      device2 = Device.make institution: institution, laboratories: [laboratory2]
      device3 = Device.make institution: institution, laboratories: [laboratory3]
      post :create, (Oj.dump results:[result: "negative"]), device_uuid: device1.secret_key
      post :create, (Oj.dump results:[result: "positive"]), device_uuid: device2.secret_key
      post :create, (Oj.dump results:[result: "positive with riff"]), device_uuid: device3.secret_key

      response = get_updates(group_by: {admin_level: 1})
      response.should eq([
        {"location"=>parent_location.id, "count"=>2},
        {"location"=>upper_leaf_location.id, "count"=>1}
      ])

      response = get_updates(group_by: {admin_level: 0})

      response.should eq([
        {"location"=>root_location.id, "count"=>3}
      ])
    end
  end

  context "Query" do
    context "Filter" do
      let(:device2) {Device.make institution: institution}

      it "should check for new events since a date" do
        Timecop.freeze(Time.utc(2013, 1, 1, 12, 0, 0))
        post :create, data, device_uuid: device.secret_key
        Timecop.freeze(Time.utc(2013, 1, 2, 12, 0, 0))
        post :create, (Oj.dump results:[result: :negative]), device_uuid: device.secret_key

        response = get_updates(since: Time.utc(2013, 1, 2, 12, 0, 0).utc.iso8601)

        response.size.should be(1)
        response.first["results"].first["result"].should eq("negative")

        response = get_updates(since: Time.utc(2013, 1, 1, 12, 0, 0).utc.iso8601)

        response.first["results"].first["result"].should eq("positive")
        response.last["results"].first["result"].should eq("negative")

        get_updates(since: Time.utc(2013, 1, 3, 12, 0, 0).utc.iso8601).should be_empty
      end

      # it "filters by an analyzed result" do
      #   post :create, (Oj.dump results:[condition: "MTB", result: :negative]), device_uuid: device.secret_key
      #   post :create, (Oj.dump results:[condition: "MTB", result: "Positive with RIFF resistance"]), device_uuid: device.secret_key

      #   response = get_updates(result: :positive)

      #   response.size.should be(1)
      #   response.first["results"].first["result"].should eq("Positive with RIFF resistance")
      # end

      it "filters by condition" do
        post :create, (Oj.dump results:[condition: "MTB", result: :positive]), device_uuid: device.secret_key
        post :create, (Oj.dump results:[condition: "Flu", result: :negative]), device_uuid: device.secret_key

        response = get_updates condition: 'MTB'

        response.size.should be(1)
        response.first["results"].first["result"].should eq("positive")
      end

      it "filters by test type" do
        post :create, (Oj.dump results:[condition: "MTB", result: :positive], test_type: :qc), device_uuid: device.secret_key
        post :create, (Oj.dump results:[condition: "MTB", result: :negative], test_type: :specimen), device_uuid: device.secret_key

        response = get_updates test_type: :specimen

        response.size.should be(1)
        response.first["results"].first["result"].should eq("negative")
      end
    end

    context "Grouping" do
      it "groups by gender in query params" do
        post :create, (Oj.dump results:[result: :positive], gender: :male), device_uuid: device.secret_key
        post :create, (Oj.dump results:[result: :negative], gender: :male), device_uuid: device.secret_key
        post :create, (Oj.dump results:[result: :negative], gender: :female), device_uuid: device.secret_key

        response = get_updates(group_by: :gender).sort_by do |event|
          event["gender"]
        end

        response.should eq([
          {"gender"=>"female", "count"=>1},
          {"gender"=>"male", "count"=>2}
        ])
      end

      it "groups by gender and assay_name in post body" do
        post :create, (Oj.dump results:[result: :positive], gender: :male, assay_name: "a"), device_uuid: device.secret_key
        post :create, (Oj.dump results:[result: :positive], gender: :male, assay_name: "a"), device_uuid: device.secret_key
        post :create, (Oj.dump results:[result: :positive], gender: :male, assay_name: "b"), device_uuid: device.secret_key
        post :create, (Oj.dump results:[result: :negative], gender: :female, assay_name: "a"), device_uuid: device.secret_key
        post :create, (Oj.dump results:[result: :negative], gender: :female, assay_name: "b"), device_uuid: device.secret_key
        post :create, (Oj.dump results:[result: :negative], gender: :female, assay_name: "b"), device_uuid: device.secret_key

        response = get_updates({}, Oj.dump(group_by: [:gender , :assay_name])).sort_by do |event|
          event["gender"] + event["assay_name"]
        end

        response.should eq([
          {"gender"=>"female", "assay_name" => "a", "count"=>1},
          {"gender"=>"female", "assay_name" => "b", "count"=>2},
          {"gender"=>"male", "assay_name" => "a", "count"=>2},
          {"gender"=>"male", "assay_name" => "b", "count"=>1}
        ])
      end
      context "CSV" do

        render_views

        it "responds a csv for a given grouping" do
          Timecop.freeze
          post :create, (Oj.dump results:[result: :positive], error_code: 1234, system_user: :jdoe), device_uuid: device.secret_key
          post :create, (Oj.dump results:[result: :negative], error_code: 1234, system_user: :jane_doe), device_uuid: device.secret_key
          post :create, (Oj.dump results:[result: :negative], error_code: 1234, system_user: :jane_doe), device_uuid: device.secret_key
          fresh_client_for institution.elasticsearch_index_name

          response = get :events, "", format: 'csv', group_by: 'system_user,error_code'

          response.status.should eq(200)
          response.content_type.should eq("text/csv")
          response.headers["Content-Disposition"].should eq("attachment; filename=\"Events-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
          response.should render_template("events")
          response.body.should eq("system_user,error_code,count\njane_doe,1234,2\njdoe,1234,1\n")
        end

        pending "should respond an empty csv if no values" do
          response = get :events, "", format: 'csv', group_by: 'system_user,error_code'

          response.status.should eq(200)
          response.content_type.should eq("text/csv")
          response.headers["Content-Disposition"].should eq("attachment; filename=\"Events-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
          response.should render_template("events")
          response.body.should eq("")
        end
      end
    end

    context "Ordering" do
      it "should order by age" do
        post :create, (Oj.dump results:[result: :positive], age: 20), device_uuid: device.secret_key
        post :create, (Oj.dump results:[result: :negative], age: 10), device_uuid: device.secret_key

        response = get_updates(order_by: :age)

        response[0]["results"].first["result"].should eq("negative")
        response[0]["age"].should eq(10)
        response[1]["results"].first["result"].should eq("positive")
        response[1]["age"].should eq(20)
      end
    end

    context "Custom Fields" do
      it "should retrieve an event custom fields by uuid", context do
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

        fresh_client_for institution.elasticsearch_index_name
        response = get :custom_fields, event_uuid: event["uuid"]
        response.status.should eq(200)
        response = Oj.load response.body

        response["custom_fields"]["foo"].should eq(1234)
        response["uuid"].should eq(event["uuid"])
      end
    end

    context "PII" do
      it "should retrieve an event PII by uuid" do
        post :create, Oj.dump(results: [result: :positive], patient_name: "jdoe"), device_uuid: device.secret_key
        event = all_elasticsearch_events.first["_source"]

        fresh_client_for institution.elasticsearch_index_name
        response = get :pii, event_uuid: event["uuid"]
        response.status.should eq(200)
        response = Oj.load response.body

        response["pii"]["patient_name"].should eq("jdoe")
        response["uuid"].should eq(event["uuid"])
      end
    end
  end
end
