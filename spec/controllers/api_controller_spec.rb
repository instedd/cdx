require 'spec_helper'

describe ApiController do
  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
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
      event.sensitive_data[:patient_id].should be_nil
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

    it "should generate a started_at date if it's not provided" do
      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["started_at"].should eq(event["created_at"])
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
          "version" : 1,
          "api_version" : "1.0.0"
        },
        "field_mapping" : [{
            "target_field" : "assay_name",
            "selector" : "assay.name",
            "type" : "string",
            "core" : true
          }]
      }}
      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["assay_name"].should eq("GX4002")
      event["created_at"].should_not eq(nil)
      event["patient_id"].should be_nil
    end

    it "stores pii according to manifest" do
      Manifest.create definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "1.0.0"
        },
        "field_mapping" : [
          {
            "target_field": "assay_name",
            "selector" : "assay.name",
            "type" : "string",
            "core" : true
          },
          {
            "target_field": "foo",
            "selector" : "patient_id",
            "type" : "integer",
            "core" : false,
            "pii": true
          }
        ]
      }}

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["assay_name"].should eq("GX4002")
      event["patient_id"].should eq(nil)
      event["foo"].should be_nil

      event = Event.first
      raw_data = event.sensitive_data
      event.decrypt.sensitive_data.should_not eq(raw_data)
      event.sensitive_data["patient_id"].should be_nil
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
            "core" : true
          }
        ]
      }}

      Manifest.create definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 2,
          "api_version" : "1.0.0"
        },
        "field_mapping" : [
          {
            "target_field": "assay_name",
            "selector" : "assay.name",
            "type" : "string",
            "core" : true
          }
        ]
      }}

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["foo"].should be_nil
      event["assay_name"].should eq("GX4002")
    end

    it "stores custom fields according to the manifest" do
      Manifest.create definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 2,
          "api_version" : "1.0.0"
        },
        "field_mapping" : [
          {
            "target_field": "foo",
            "selector" : "some_field",
            "type" : "string",
            "core" : false,
            "pii": false,
            "indexed": false
          }
        ]
      }}

      post :create, Oj.dump(some_field: 1234), device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["foo"].should be_nil

      event = Event.first.decrypt
      event.sensitive_data["some_field"].should be_nil
      event.sensitive_data["foo"].should be_nil
      event.custom_fields[:foo].should eq(1234)
      event.custom_fields["foo"].should eq(1234)
    end

    it "validates the data type" do
      Manifest.create definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "api_version": "1",
          "version" : 1
        },
        "field_mapping" : [{
            "target_field" : "error_code",
            "selector" : "error_code",
            "core" : true,
            "type" : "integer"
          }]
      }}
      post :create, Oj.dump(error_code: 1234), device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["error_code"].should eq(1234)

      post :create, Oj.dump(error_code: "foo"), device_uuid: device.secret_key

      response.code.should eq("422")
      Oj.load(response.body)["errors"].should eq("'foo' is not a valid value for 'error_code' (must be an integer)")
    end
  end

  context "Laboratories" do
    it "should list the laboratories" do
      institution = Institution.make user: user
      lab_ids = 3.times.map do
        lab = Laboratory.make(institution: institution)
        {'id' => lab.id, 'name' => lab.name, 'location' => lab.location_id}
      end

      result = get :laboratories, format: 'json'
      Oj.load(result.body).should eq({'total_count' => 3, 'laboratories' => lab_ids})
    end

    it "should list the laboratories for a given institution" do
      institution = Institution.make user: user
      lab_ids = 3.times.map do
        lab = Laboratory.make(institution: institution)
        {'id' => lab.id, 'name' => lab.name, 'location' => lab.location_id}
      end

      Laboratory.make institution: (Institution.make user: user)

      get :laboratories, institution_id: institution.id, format: 'json'
      Oj.load(response.body).should eq({'total_count' => 3, 'laboratories' => lab_ids})
    end

    context 'CSV' do
      def check_laboratories_csv(r)
        r.status.should eq(200)
        r.content_type.should eq("text/csv")
        r.headers["Content-Disposition"].should eq("attachment; filename=\"Laboratories-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
        r.should render_template("laboratories")
      end

      let(:institution) { Institution.make user: user }
      let(:lab) { Laboratory.make(institution: institution) }

      render_views

      before(:each) { Timecop.freeze }

      it "should respond a csv" do
        institution
        lab

        get :laboratories, format: 'csv'

        check_laboratories_csv response
        response.body.should eq("id,name,location\n#{lab.id},#{lab.name},#{lab.location_id}\n")
      end

      it "renders column names even when there are no laboratories to render" do
        institution

        get :laboratories, format: 'csv'

        check_laboratories_csv response
        response.body.should eq("id,name,location\n")
      end
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
      event["location"]['admin_level_0'].should eq(root_location.id)
      event["location"]['admin_level_1'].should eq(parent_location.id)
      event["location"]['admin_level_2'].should eq(leaf_location1.id)
    end

    it "should store the parent location id when the device is registered more than one laboratory" do
      device.laboratories = [laboratory1, laboratory2]
      device.save!

      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["location_id"].should eq(parent_location.id)
      event["laboratory_id"].should be_nil
      event["parent_locations"].should eq([root_location.id, parent_location.id].sort)
      event["location"]['admin_level_0'].should eq(root_location.id)
      event["location"]['admin_level_1'].should eq(parent_location.id)
    end

    it "should store the root location id when the device is registered more than one laboratory" do
      device.laboratories = [laboratory2, laboratory3]
      device.save!

      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["location_id"].should eq(root_location.id)
      event["laboratory_id"].should be_nil
      event["parent_locations"].should eq([root_location.id])
      event["location"]['admin_level_0'].should eq(root_location.id)
    end

    it "should store the root location id when the device is registered more than one laboratory with another tree order" do
      device.laboratories = [laboratory3, laboratory2]
      device.save!

      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["location_id"].should eq(root_location.id)
      event["laboratory_id"].should be_nil
      event["parent_locations"].should eq([root_location.id])
      event["location"]['admin_level_0'].should eq(root_location.id)
    end

    it "should store nil if no location was found" do
      device.laboratories = []
      device.save!

      post :create, data, device_uuid: device.secret_key

      event = all_elasticsearch_events.first["_source"]
      event["location_id"].should be_nil
      event["laboratory_id"].should be_nil
      event["parent_locations"].should eq([])
      event["location"].should eq({})
    end

    it "filters by location" do
      device1 = Device.make institution: institution, laboratories: [laboratory1]
      device2 = Device.make institution: institution, laboratories: [laboratory2]
      device3 = Device.make institution: institution, laboratories: [laboratory3]
      post :create, (Oj.dump results:[condition: "flu_a"]), device_uuid: device1.secret_key
      post :create, (Oj.dump results:[condition: "flu_b"]), device_uuid: device2.secret_key
      post :create, (Oj.dump results:[condition: "mtb"]), device_uuid: device3.secret_key

      response = get_updates(location: leaf_location1.id)

      response.first["results"].first["condition"].should eq("flu_a")

      response = get_updates(location: leaf_location2.id)

      response.first["results"].first["condition"].should eq("flu_b")

      response = get_updates(location: parent_location.id).sort_by do |event|
        event["results"].first["condition"]
      end

      response.size.should eq(2)
      response[0]["results"].first["condition"].should eq("flu_a")
      response[1]["results"].first["condition"].should eq("flu_b")

      response = get_updates(location: root_location.id).sort_by do |event|
        event["results"].first["condition"]
      end

      response.size.should eq(3)
      response[0]["results"].first["condition"].should eq("flu_a")
      response[1]["results"].first["condition"].should eq("flu_b")
      response[2]["results"].first["condition"].should eq("mtb")
    end

    it "groups by administrative level" do
      device1 = Device.make institution: institution, laboratories: [laboratory1]
      device2 = Device.make institution: institution, laboratories: [laboratory2]
      device3 = Device.make institution: institution, laboratories: [laboratory3]
      post :create, (Oj.dump results:[condition: "flu_a"]), device_uuid: device1.secret_key
      post :create, (Oj.dump results:[condition: "flu_b"]), device_uuid: device2.secret_key
      post :create, (Oj.dump results:[condition: "mtb"]), device_uuid: device3.secret_key

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

    context "Policies" do
      it "allows a user to query events of it's own institutions" do
        device2 = Device.make
        post :create, (Oj.dump results:[condition: "mtb", result: :positive]), device_uuid: device.secret_key
        post :create, (Oj.dump results:[condition: "mtb", result: :negative]), device_uuid: device2.secret_key

        fresh_client_for device2.institution.elasticsearch_index_name

        response = get_updates condition: 'mtb'

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("positive")
      end
    end

    context "Filter" do
      let(:device2) {Device.make institution: institution}

      it "should check for new events since a date" do
        Timecop.freeze(Time.utc(2013, 1, 1, 12, 0, 0))
        post :create, data, device_uuid: device.secret_key
        Timecop.freeze(Time.utc(2013, 1, 2, 12, 0, 0))
        post :create, (Oj.dump results:[result: :negative]), device_uuid: device.secret_key

        response = get_updates(created_at_since: Time.utc(2013, 1, 2, 12, 0, 0).utc.iso8601)

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("negative")

        response = get_updates(created_at_since: Time.utc(2013, 1, 1, 12, 0, 0).utc.iso8601)

        response.first["results"].first["result"].should eq("positive")
        response.last["results"].first["result"].should eq("negative")

        get_updates(created_at_since: Time.utc(2013, 1, 3, 12, 0, 0).utc.iso8601).should be_empty
      end

       it "filters by an analyzed result" do
         post :create, (Oj.dump results:[condition: "mtb", result: :negative]), device_uuid: device.secret_key
         post :create, (Oj.dump results:[condition: "mtb", result: :positive]), device_uuid: device.secret_key

         response = get_updates(result: :positive)

         response.size.should eq(1)
         response.first["results"].first["result"].should eq("positive")
       end

      it "filters by condition" do
        post :create, (Oj.dump results:[condition: "mtb", result: :positive]), device_uuid: device.secret_key
        post :create, (Oj.dump results:[condition: "flu", result: :negative]), device_uuid: device.secret_key

        response = get_updates condition: 'mtb'

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("positive")
      end

      it "filters by test type" do
        post :create, (Oj.dump results:[condition: "mtb", result: :positive], test_type: :qc), device_uuid: device.secret_key
        post :create, (Oj.dump results:[condition: "mtb", result: :negative], test_type: :specimen), device_uuid: device.secret_key

        response = get_updates test_type: :specimen

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("negative")
      end

      it "filters by condition with non default manifest" do
        Manifest.create definition: %{{
          "metadata" : {
            "device_models" : ["#{device.device_model.name}"],
            "version" : 2,
            "api_version" : "1.0.0"
          },
          "field_mapping" : [
            {
              "target_field" : "results[*].condition",
              "selector" : "results[*].condition",
              "type" : "enum",
              "core" : true,
              "pii" : false,
              "indexed" : true,
              "options" : [
                "flu_a",
                "flu_b",
                "h1n1",
                "ct",
                "mtb"
              ]
            },
            {
              "target_field" : "results[*].result",
              "selector" : "results[*].result",
              "type" : "enum",
              "core" : true,
              "indexed" : true,
              "pii" : false,
              "options" : [
                "positive",
                "negative"
              ]
            }
          ]
        }}
        Manifest.count.should eq(1)
        post :create, (Oj.dump results:[condition: "mtb", result: :positive]), device_uuid: device.secret_key
        post :create, (Oj.dump results:[condition: "mtb", result: :negative]), device_uuid: device.secret_key
        Event.count.should eq(2)
        response = get_updates condition: 'mtb'
        response.size.should eq(2)
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
        def check_csv(r)
          r.status.should eq(200)
          r.content_type.should eq("text/csv")
          r.headers["Content-Disposition"].should eq("attachment; filename=\"Events-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
          r.should render_template("events")
        end

        render_views

        before(:each) { Timecop.freeze }

        it "responds a csv for a given grouping" do
          post :create, (Oj.dump results:[result: :positive], error_code: 1234, system_user: :jdoe), device_uuid: device.secret_key
          post :create, (Oj.dump results:[result: :negative], error_code: 1234, system_user: :jane_doe), device_uuid: device.secret_key
          post :create, (Oj.dump results:[result: :negative], error_code: 1234, system_user: :jane_doe), device_uuid: device.secret_key

          fresh_client_for institution.elasticsearch_index_name

          response = get :events, "", format: 'csv', group_by: 'system_user,error_code'

          check_csv response
          response.body.should eq("system_user,error_code,count\njane_doe,1234,2\njdoe,1234,1\n")
        end

        it "returns a csv with columns for a given grouping even when there are no results" do
          get :events, "", format: 'csv', group_by: 'system_user,error_code'
          response.body.should eq("system_user,error_code,count\n")
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
            "version" : 2,
            "api_version" : "1.0.0"
          },
          "field_mapping" : [
            {
              "target_field": "foo",
              "selector" : "some_field",
              "type" : "string",
              "core" : false,
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
