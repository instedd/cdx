require 'spec_helper'

describe Api::EventsController, elasticsearch: true, validate_manifest: false do

  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  let(:data) {Oj.dump results: [result: :positive]}
  before(:each) {sign_in user}

  def get_updates(options, body="")
    fresh_client_for institution.elasticsearch_index_name
    response = get :index, body, options.merge(format: 'json')
    response.status.should eq(200)
    Oj.load(response.body)["events"]
  end

  context "Query" do
    context "Policies" do
      it "allows a user to query events of it's own institutions" do
        device2 = Device.make
        post :create, (Oj.dump results:[condition: "mtb", result: :positive]), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[condition: "mtb", result: :negative]), device_id: device2.uuid, authentication_token: device2.secret_key

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
        post :create, data, device_id: device.uuid, authentication_token: device.secret_key
        Timecop.freeze(Time.utc(2013, 1, 2, 12, 0, 0))
        post :create, (Oj.dump results:[result: :negative]), device_id: device.uuid, authentication_token: device.secret_key

        response = get_updates(created_at_since: Time.utc(2013, 1, 2, 12, 0, 0).utc.iso8601)

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("negative")

        response = get_updates(created_at_since: Time.utc(2013, 1, 1, 12, 0, 0).utc.iso8601)

        response.first["results"].first["result"].should eq("positive")
        response.last["results"].first["result"].should eq("negative")

        get_updates(created_at_since: Time.utc(2013, 1, 3, 12, 0, 0).utc.iso8601).should be_empty
      end

       it "filters by an analyzed result" do
         post :create, (Oj.dump results:[condition: "mtb", result: :negative]), device_id: device.uuid, authentication_token: device.secret_key
         post :create, (Oj.dump results:[condition: "mtb", result: :positive]), device_id: device.uuid, authentication_token: device.secret_key

         response = get_updates(result: :positive)

         response.size.should eq(1)
         response.first["results"].first["result"].should eq("positive")
       end

      it "filters by condition" do
        post :create, (Oj.dump results:[condition: "mtb", result: :positive]), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[condition: "flu", result: :negative]), device_id: device.uuid, authentication_token: device.secret_key

        response = get_updates condition: 'mtb'

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("positive")
      end

      it "filters by event_id" do
        post :create, (Oj.dump event_id: 2, results:[condition: "mtb", result: :positive]), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[condition: "flu", result: :negative]), device_id: device.uuid, authentication_token: device.secret_key

        response = get_updates event: 2

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("positive")
      end

      it "filters by test type" do
        post :create, (Oj.dump results:[condition: "mtb", result: :positive], test_type: :qc), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[condition: "mtb", result: :negative], test_type: :specimen), device_id: device.uuid, authentication_token: device.secret_key

        response = get_updates test_type: :specimen

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("negative")
      end

      it "filters for more than one value" do
        post :create, (Oj.dump results:[condition: "mtb", result: :positive], gender: :male), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[condition: "mtb", result: :negative], gender: :female), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[condition: "flu", result: :negative]), device_id: device.uuid, authentication_token: device.secret_key

        response = get_updates(gender: [:male, :female]).sort_by do |event|
          event["results"].first["result"]
        end

        response.size.should eq(2)
        response.first["results"].first["result"].should eq("negative")
        response.last["results"].first["result"].should eq("positive")
      end
    end

    context "Grouping" do
      it "groups by gender in query params" do
        post :create, (Oj.dump results:[result: :positive], gender: :male), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[result: :negative], gender: :male), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[result: :negative], gender: :female), device_id: device.uuid, authentication_token: device.secret_key

        response = get_updates(group_by: :gender).sort_by do |event|
          event["gender"]
        end

        response.should eq([
          {"gender"=>"female", "count"=>1},
          {"gender"=>"male", "count"=>2}
        ])
      end

      it "groups by gender and assay_name in post body" do
        post :create, (Oj.dump results:[result: :positive], gender: :male, assay_name: "a"), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[result: :positive], gender: :male, assay_name: "a"), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[result: :positive], gender: :male, assay_name: "b"), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[result: :negative], gender: :female, assay_name: "a"), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[result: :negative], gender: :female, assay_name: "b"), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[result: :negative], gender: :female, assay_name: "b"), device_id: device.uuid, authentication_token: device.secret_key

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

      it "groups and filters for more than one value" do
        post :create, (Oj.dump results:[condition: "mtb", result: :positive], gender: :male), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[condition: "mtb", result: :positive], gender: :male), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[condition: "mtb", result: :negative], gender: :female), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[condition: "flu", result: :negative]), device_id: device.uuid, authentication_token: device.secret_key

        response = get_updates("page_size"=>0, "group_by"=>["gender"], "gender"=>["male", "female"]).sort_by do |event|
          event["gender"]
        end

        response.should eq([
          {"gender"=>"female", "count"=>1},
          {"gender"=>"male", "count"=>2}
        ])
      end

      context "CSV" do
        def check_csv(r)
          r.status.should eq(200)
          r.content_type.should eq("text/csv")
          r.headers["Content-Disposition"].should eq("attachment; filename=\"Events-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
          r.should render_template("api/events/index")
        end

        render_views

        before(:each) { Timecop.freeze }

        it "responds a csv for a given grouping" do
          post :create, (Oj.dump results:[result: :positive], error_code: 1234, system_user: :jdoe), device_id: device.uuid, authentication_token: device.secret_key
          post :create, (Oj.dump results:[result: :negative], error_code: 1234, system_user: :jane_doe), device_id: device.uuid, authentication_token: device.secret_key
          post :create, (Oj.dump results:[result: :negative], error_code: 1234, system_user: :jane_doe), device_id: device.uuid, authentication_token: device.secret_key

          fresh_client_for institution.elasticsearch_index_name

          response = get :index, "", format: 'csv', group_by: 'system_user,error_code'

          check_csv response
          response.body.should eq("system_user,error_code,count\njane_doe,1234,2\njdoe,1234,1\n")
        end

        it "returns a csv with columns for a given grouping even when there are no results" do
          get :index, "", format: 'csv', group_by: 'system_user,error_code'
          response.body.should eq("system_user,error_code,count\n")
        end
      end
    end

    context "Ordering" do
      it "should order by age" do
        post :create, (Oj.dump results:[result: :positive], age: 20), device_id: device.uuid, authentication_token: device.secret_key
        post :create, (Oj.dump results:[result: :negative], age: 10), device_id: device.uuid, authentication_token: device.secret_key

        response = get_updates(order_by: :age)

        response[0]["results"].first["result"].should eq("negative")
        response[0]["age"].should eq(10)
        response[1]["results"].first["result"].should eq("positive")
        response[1]["age"].should eq(20)
      end
    end

    context "Custom Fields" do
      it "should retrieve an event custom fields by uuid", context do
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
        post :create, Oj.dump(some_field: 1234), device_id: device.uuid, authentication_token: device.secret_key
        event = all_elasticsearch_events_for(institution).first["_source"]

        fresh_client_for institution.elasticsearch_index_name
        response = get :custom_fields, id: event["uuid"]
        response.status.should eq(200)
        response = Oj.load response.body

        response["custom_fields"]["foo"].should eq(1234)
        response["uuid"].should eq(event["uuid"])
      end
    end

    context "PII" do
      it "should retrieve an event PII by uuid" do
        definition = %{{
          "metadata" : {
            "device_models" : ["#{device.device_model.name}"],
            "api_version" : "1.1.0",
            "version" : "1.0.0",
            "source" : {"type" : "json"}
          },
          "field_mapping" : {
            "event" : [
              {
                "target_field" : "results[*].result",
                "source" : {"lookup" : "results[*].result"},
                "core" : true,
                "indexed" : true,
                "type" : "enum",
                "options" : [
                  "positive",
                  "negative"
                ]
              }
            ],
            "patient" : [
              {
                "target_field" : "patient_name",
                "source" : {"lookup" : "patient_name"},
                "pii" : true
              }
            ]
          }
        }}

        Manifest.create! definition: definition

        post :create, Oj.dump(results: [result: :positive], patient_name: "jdoe"), device_id: device.uuid, authentication_token: device.secret_key
        event = all_elasticsearch_events_for(institution).first["_source"]

        fresh_client_for institution.elasticsearch_index_name
        response = get :pii, id: event["uuid"]
        response.status.should eq(200)
        response = Oj.load response.body

        response["pii"]["patient_name"].should eq("jdoe")
        response["uuid"].should eq(event["uuid"])
      end
    end

    context "Schema" do
      let!(:root_location) { Location.create_default }
      let!(:parent_location) { Location.make parent: root_location }

      it "should retrieve the schema for a given assay_name" do
        definition = %{{
          "metadata" : {
            "device_models" : ["foo"],
            "api_version" : "1.1.0",
            "version" : "1.0.1",
            "source" : {"type" : "json"}
          },
          "field_mapping" : {
            "event" : [
              {
                "target_field" : "assay_name",
                "source" : {"lookup" : "assay_name"},
                "core" : true,
                "indexed" : true,
                "type" : "enum",
                "options" : [
                  "first_assay",
                  "second_assay"
                ]
              },
              {
                "target_field" : "start_time",
                "source" : {"lookup" : "start_time"},
                "core" : true,
                "pii" : true,
                "type" : "date"
              },
              {
                "target_field" : "results[*].result",
                "source" : {"lookup" : "result"},
                "type" : "enum",
                "core" : true,
                "indexed" : true,
                "options" : [
                  "positive",
                  "positive_with_riff",
                  "negative"
                ]
              },
              {
                "target_field" : "location",
                "source" : {"lookup" : "location"},
                "core" : true,
                "indexed" : true,
                "type" : "location"
              }
            ],
            "patient" : [
              {
                "target_field" : "patient_name",
                "source" : {"lookup" : "patient_information.name"},
                "pii" : true,
                "type" : "string"
              },
              {
                "target_field" : "age",
                "source" : {"lookup" : "age"},
                "type" : "integer",
                "indexed" : true,
                "core" : true,
                "valid_values" : {
                  "range" : {
                    "min" : 0,
                    "max" : 125
                  }
                }
              },
              {
                "target_field" : "patient_location",
                "source" : {"lookup" : "patient_location"},
                "indexed" : true,
                "type" : "location"
              }
            ]
          }
        }}
        Manifest.create! definition: definition

        definition = %{{
          "metadata" : {
            "device_models" : ["foo"],
            "api_version" : "1.1.0",
            "version" : "1.0.0",
            "source" : {"type" : "json"}
          },
          "field_mapping" : { "event" : [
            {
              "target_field" : "assay_name",
              "source" : {"lookup" : "assay_name"},
              "core" : true,
              "indexed" : true,
              "type" : "enum",
              "options" : [
                "first_assay",
                "second_assay"
              ]
            }
          ]}
        }}

        Manifest.create! definition: definition

        date_schema = {
          "title" => "Start Time",
          "type" => "string",
          "format" => "date-time",
          "resolution" => "second",
          "searchable" => false
        }

        enum_schema = {
          "title" => "Result",
          "type" => "string",
          "enum" => ["positive", "positive_with_riff", "negative"],
          "values" => {
            "positive" => { "name" => "Positive", "kind" => "positive" },
            "positive_with_riff" => { "name" => "Positive With Riff", "kind" => "positive" },
            "negative" => { "name" => "Negative", "kind" => "negative" }
          },
          "searchable" => true
        }

        string_schema = {
          "title" => "Patient Name",
          "type" => "string",
          "searchable" => false
        }

        number_schema = {
          "title" => "Age",
          "type" => "integer",
          "minimum" => 0,
          "maximum" => 125,
          "searchable" => true
        }

        locations = Location.all
        location_schema = {
          "title" => "Location",
          "type" => "string",
          "enum" => [ root_location.geo_id.to_s, parent_location.geo_id.to_s ],
          "locations" => {
            "#{root_location.geo_id.to_s}" => {"name" => root_location.name, "level" => root_location.admin_level, "parent" => nil, "lat" => root_location.lat, "lng" => root_location.lng},
            "#{parent_location.geo_id.to_s}" => {"name" => parent_location.name, "level" => parent_location.admin_level, "parent" => root_location.geo_id, "lat" => parent_location.lat, "lng" => parent_location.lng}
          },
          "searchable" => true
        }

        patient_location_schema = {
          "title" => "Patient Location",
          "type" => "string",
          "enum" => [ root_location.geo_id.to_s, parent_location.geo_id.to_s ],
          "locations" => {
            "#{root_location.geo_id.to_s}" => {"name" => root_location.name, "level" => root_location.admin_level, "parent" => nil, "lat" => root_location.lat, "lng" => root_location.lng},
            "#{parent_location.geo_id.to_s}" => {"name" => parent_location.name, "level" => parent_location.admin_level, "parent" => root_location.geo_id, "lat" => parent_location.lat, "lng" => parent_location.lng}
          },
          "searchable" => false
        }

        response = get :schema, assay_name: "first_assay", locale: "es-AR", format: 'json'
        schema = Oj.load response.body

        schema["errors"].should be_nil
        schema["$schema"].should eq("http://json-schema.org/draft-04/schema#")
        schema["type"].should eq("object")
        schema["title"].should eq("first_assay.es-AR")

        schema["properties"]["start_time"].should eq(date_schema)
        schema["properties"]["result"].should eq(enum_schema)
        schema["properties"]["patient_name"].should eq(string_schema)
        schema["properties"]["age"].should eq(number_schema)
        schema["properties"]["patient_location"].should eq(patient_location_schema)
        schema["properties"]["location"].should eq(location_schema)
      end

      it "should return an empty schema with all the assay_names available if none is provided" do
        Manifest.create! definition: %{{
          "metadata" : {
            "device_models" : ["foo"],
            "api_version" : "1.1.0",
            "version" : "1.0.1",
            "source" : {"type" : "json"}
          },
          "field_mapping" : { "event" : [
            {
              "target_field" : "assay_name",
              "source" : {"lookup" : "assay_name"},
              "core" : true,
              "indexed" : true,
              "type" : "enum",
              "options" : [
                "first_assay",
                "second_assay"
              ]
            }
          ]}
        }}

        manifest = Manifest.create! definition: %{{
          "metadata" : {
            "device_models" : ["bar"],
            "api_version" : "1.1.0",
            "version" : "1.0.1",
            "source" : {"type" : "json"}
          },
          "field_mapping" : { "event" : [
            {
              "target_field" : "assay_name",
              "source" : {"lookup" : "assay_name"},
              "core" : true,
              "indexed" : true,
              "type" : "enum",
              "options" : [
                "cardridge_1",
                "cardridge_2"
              ]
            }
          ]}
        }}

        response = get :schema, format: 'json'
        schema = Oj.load response.body

        schema["$schema"].should eq("http://json-schema.org/draft-04/schema#")
        schema["type"].should eq("object")
        schema["title"].should eq("en-US")

        schema["properties"]["assay_name"].should eq({
          "title" => "Assay Name",
          "type" => "string",
          "searchable" => true,
          "enum" => ["first_assay", "second_assay", "cardridge_1", "cardridge_2"],
          "values" => {
            "first_assay" => {"name" => "First Assay"},
            "second_assay" => {"name" => "Second Assay"},
            "cardridge_1" => {"name" => "Cardridge 1"},
            "cardridge_2" => {"name" => "Cardridge 2"}
          }
        })
      end
    end
  end
end
