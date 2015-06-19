require 'spec_helper'

describe Api::TestsController, elasticsearch: true, validate_manifest: false do

  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  let(:data) {Oj.dump results: [result: :positive]}
  before(:each) {sign_in user}

  def get_updates(options, body="")
    fresh_client_for institution.elasticsearch_index_name
    response = get :index, body, options.merge(format: 'json')
    response.status.should eq(200)
    Oj.load(response.body)["tests"]
  end

  context "Query" do
    context "Policies" do
      it "allows a user to query tests of it's own institutions" do
        device2 = Device.make

        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "mtb", result: :positive])
        DeviceMessage.create_and_process device: device2, plain_text_data: (Oj.dump results:[condition: "mtb", result: :negative])

        fresh_client_for device2.institution.elasticsearch_index_name

        response = get_updates condition: 'mtb'

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("positive")
      end
    end

    context "Filter" do
      let(:device2) {Device.make institution: institution}

      it "should check for new tests since a date" do
        Timecop.freeze(Time.utc(2013, 1, 1, 12, 0, 0))
        DeviceMessage.create_and_process device: device, plain_text_data: data
        Timecop.freeze(Time.utc(2013, 1, 2, 12, 0, 0))
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :negative])

        response = get_updates(created_at_since: Time.utc(2013, 1, 2, 12, 0, 0).utc.iso8601)

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("negative")

        response = get_updates(created_at_since: Time.utc(2013, 1, 1, 12, 0, 0).utc.iso8601)

        response.first["results"].first["result"].should eq("positive")
        response.last["results"].first["result"].should eq("negative")

        get_updates(created_at_since: Time.utc(2013, 1, 3, 12, 0, 0).utc.iso8601).should be_empty
      end

      it "filters by an analyzed result" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "mtb", result: :negative])
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "mtb", result: :positive])

        response = get_updates(result: :positive)

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("positive")
      end

      it "filters by condition" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "mtb", result: :positive])
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "flu", result: :negative])

        response = get_updates condition: 'mtb'

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("positive")
      end

      it "filters by test_id" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test_id: 2, results:[condition: "mtb", result: :positive])
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "flu", result: :negative])

        response = get_updates test: 2

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("positive")
      end

      it "filters by test type" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "mtb", result: :positive], test_type: :qc)
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "mtb", result: :negative], test_type: :specimen)

        response = get_updates test_type: :specimen

        response.size.should eq(1)
        response.first["results"].first["result"].should eq("negative")
      end

      it "filters for more than one value" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "mtb", result: :positive], gender: :male)
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "mtb", result: :negative], gender: :female)
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "flu", result: :negative])

        response = get_updates(gender: [:male, :female]).sort_by do |test|
          test["results"].first["result"]
        end

        response.size.should eq(2)
        response.first["results"].first["result"].should eq("negative")
        response.last["results"].first["result"].should eq("positive")
      end
    end

    context "Grouping" do
      it "groups by gender in query params" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :positive], gender: :male)
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :negative], gender: :male)
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :negative], gender: :female)

        response = get_updates(group_by: :gender).sort_by do |test|
          test["gender"]
        end

        response.should eq([
          {"gender"=>"female", "count"=>1},
          {"gender"=>"male", "count"=>2}
        ])
      end

      it "groups by gender and assay_name in post body" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :positive], gender: :male, assay_name: "a")
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :positive], gender: :male, assay_name: "a")
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :positive], gender: :male, assay_name: "b")
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :negative], gender: :female, assay_name: "a")
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :negative], gender: :female, assay_name: "b")
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :negative], gender: :female, assay_name: "b")

        response = get_updates({}, Oj.dump(group_by: [:gender , :assay_name])).sort_by do |test|
          test["gender"] + test["assay_name"]
        end

        response.should eq([
          {"gender"=>"female", "assay_name" => "a", "count"=>1},
          {"gender"=>"female", "assay_name" => "b", "count"=>2},
          {"gender"=>"male", "assay_name" => "a", "count"=>2},
          {"gender"=>"male", "assay_name" => "b", "count"=>1}
        ])
      end

      it "groups and filters for more than one value" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "mtb", result: :positive], gender: :male)
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "mtb", result: :positive], gender: :male)
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "mtb", result: :negative], gender: :female)
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[condition: "flu", result: :negative])

        response = get_updates("page_size"=>0, "group_by"=>["gender"], "gender"=>["male", "female"]).sort_by do |test|
          test["gender"]
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
          r.headers["Content-Disposition"].should eq("attachment; filename=\"Tests-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
          r.should render_template("api/tests/index")
        end

        render_views

        before(:each) { Timecop.freeze }

        it "responds a csv for a given grouping" do
          DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :positive], error_code: 1234, system_user: :jdoe)
          DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :negative], error_code: 1234, system_user: :jane_doe)
          DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :negative], error_code: 1234, system_user: :jane_doe)

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
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :positive], age: 20)
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump results:[result: :negative], age: 10)

        response = get_updates(order_by: :age)

        response[0]["results"].first["result"].should eq("negative")
        response[0]["age"].should eq(10)
        response[1]["results"].first["result"].should eq("positive")
        response[1]["age"].should eq(20)
      end
    end

    context "Custom Fields" do
      it "should retrieve an test custom fields by uuid", context do
        Manifest.create! definition: %{{
          "metadata" : {
            "device_models" : ["#{device.device_model.name}"],
            "version" : 2,
            "api_version" : "1.1.0",
            "source" : {"type" : "json"}
          },
          "field_mapping" : { "test" : [
            {
              "target_field" : "foo",
              "source" : {"lookup" : "some_field"},
              "type" : "string"
            }
          ]}
        }}
        DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(some_field: 1234)
        test = all_elasticsearch_tests_for(institution).first["_source"]

        fresh_client_for institution.elasticsearch_index_name
        response = get :custom_fields, id: test["uuid"]
        response.status.should eq(200)
        response = Oj.load response.body

        response["custom_fields"]["foo"].should eq(1234)
        response["uuid"].should eq(test["uuid"])
      end
    end

    context "PII" do
      it "should retrieve an test PII by uuid" do
        definition = %{{
          "metadata" : {
            "device_models" : ["#{device.device_model.name}"],
            "api_version" : "1.1.0",
            "version" : "1.0.0",
            "source" : {"type" : "json"}
          },
          "field_mapping" : {
            "test" : [
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

        DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(results: [result: :positive], patient_name: "jdoe")
        test = all_elasticsearch_tests_for(institution).first["_source"]

        fresh_client_for institution.elasticsearch_index_name
        response = get :pii, id: test["uuid"]
        response.status.should eq(200)
        response = Oj.load response.body

        response["pii"]["patient"]["patient_name"].should eq("jdoe")
        response["uuid"].should eq(test["uuid"])
      end
    end

    context "Schema" do

      it "should return test schema" do
        schema = double('schema')
        schema.should_receive(:build).and_return('a schema definition')
        TestsSchema.should_receive(:for).with('es-AR').and_return(schema)

        response = get :schema, locale: "es-AR", format: 'json'

        response_schema = Oj.load response.body
        response_schema.should eq('a schema definition')
      end

    end
  end
end
