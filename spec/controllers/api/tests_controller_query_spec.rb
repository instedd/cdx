require 'spec_helper'

describe Api::EventsController, elasticsearch: true, validate_manifest: false do

  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  let(:data) {Oj.dump test:{assays: [qualitative_result: :positive]}}
  before(:each) {sign_in user}

  def get_updates(options, body="")
    refresh_index
    response = get :index, body, options.merge(format: 'json')
    response.status.should eq(200)
    Oj.load(response.body)["tests"]
  end

  context "Query" do
    context "Policies" do
      it "allows a user to query tests of it's own institutions" do
        device2 = Device.make

        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[{name: "mtb", qualitative_result: :positive}]})
        DeviceMessage.create_and_process device: device2, plain_text_data: (Oj.dump test:{assays:[{name: "mtb", qualitative_result: :negative}]})

        refresh_index

        response = get_updates 'test.assays.name' => 'mtb'

        response.size.should eq(1)
        response.first["test"]["assays"].first["qualitative_result"].should eq("positive")
      end
    end

    context "Filter" do
      let(:device2) {Device.make institution: institution}

      it "should check for new tests since a date" do
        Timecop.freeze(Time.utc(2013, 1, 1, 12, 0, 0))
        DeviceMessage.create_and_process device: device, plain_text_data: data
        Timecop.freeze(Time.utc(2013, 1, 2, 12, 0, 0))
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :negative]})

        response = get_updates('test.reported_time_since' => Time.utc(2013, 1, 2, 12, 0, 0).utc.iso8601)
        response.size.should eq(1)
        response.first["test"]["assays"].first["qualitative_result"].should eq("negative")

        response = get_updates('test.reported_time_since' => Time.utc(2013, 1, 1, 12, 0, 0).utc.iso8601)

        response.first["test"]["assays"].first["qualitative_result"].should eq("positive")
        response.last["test"]["assays"].first["qualitative_result"].should eq("negative")

        get_updates('test.reported_time_since' => Time.utc(2013, 1, 3, 12, 0, 0).utc.iso8601).should be_empty
      end

      it "filters by an analyzed qualitative_result" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", qualitative_result: :negative]})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", qualitative_result: :positive]})

        response = get_updates('test.assays.qualitative_result' => :positive)

        response.size.should eq(1)
        response.first["test"]["assays"].first["qualitative_result"].should eq("positive")
      end

      it "filters by name" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", qualitative_result: :positive]})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "flu", qualitative_result: :negative]})

        response = get_updates 'test.assays.name' => 'mtb'

        response.size.should eq(1)
        response.first["test"]["assays"].first["qualitative_result"].should eq("positive")
      end

      it "filters by test_id" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{id: 2, assays:[name: "mtb", qualitative_result: :positive]})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "flu", qualitative_result: :negative]})

        response = get_updates 'test.id' => 2

        response.size.should eq(1)
        response.first["test"]["assays"].first["qualitative_result"].should eq("positive")
      end

      it "filters by test type" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", qualitative_result: :positive], type: :qc})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", qualitative_result: :negative], type: :specimen})

        response = get_updates 'test.type' => :specimen

        response.size.should eq(1)
        response.first["test"]["assays"].first["qualitative_result"].should eq("negative")
      end

      it "filters for more than one value" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", qualitative_result: :positive]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", qualitative_result: :negative]}, patient: {gender: :female})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test: {assays:[name: "flu", qualitative_result: :negative]})

        response = get_updates('patient.gender' => [:male, :female]).sort_by do |test|
          test["test"]["assays"].first["qualitative_result"]
        end

        response.size.should eq(2)
        response.first["test"]["assays"].first["qualitative_result"].should eq("negative")
        response.last["test"]["assays"].first["qualitative_result"].should eq("positive")
      end
    end

    context "Grouping" do
      it "groups by gender in query params" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :positive]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :negative]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :negative]}, patient: {gender: :female})

        response = get_updates(group_by: 'patient.gender').sort_by do |test|
          test["patient.gender"]
        end

        response.should eq([
          {"patient.gender"=>"female", "count"=>1},
          {"patient.gender"=>"male", "count"=>2}
        ])
      end

      it "groups by gender and qualitative_result in post body" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :positive]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :negative]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :negative]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :positive]}, patient: {gender: :female})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :positive]}, patient: {gender: :female})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :negative]}, patient: {gender: :female})

        response = get_updates({}, Oj.dump(group_by: ['patient.gender', 'test.assays.qualitative_result'])).sort_by do |test|
          test["patient.gender"] + test["test.assays.qualitative_result"]
        end

        response.should eq([
          {"patient.gender"=>"female", "test.assays.qualitative_result" => "negative", "count"=>1},
          {"patient.gender"=>"female", "test.assays.qualitative_result" => "positive", "count"=>2},
          {"patient.gender"=>"male", "test.assays.qualitative_result" => "negative", "count"=>2},
          {"patient.gender"=>"male", "test.assays.qualitative_result" => "positive", "count"=>1}
        ])
      end

      it "groups and filters for more than one value" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", qualitative_result: :positive]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", qualitative_result: :positive]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", qualitative_result: :negative]}, patient: {gender: :female})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "flu", qualitative_result: :negative]})

        response = get_updates("page_size"=>0, "group_by"=>["patient.gender"], "patient.gender"=>["male", "female"]).sort_by do |test|
          test["patient.gender"]
        end

        response.should eq([
          {"patient.gender"=>"female", "count"=>1},
          {"patient.gender"=>"male", "count"=>2}
        ])
      end

      context "CSV" do
        def check_csv(r)
          r.status.should eq(200)
          r.content_type.should eq("text/csv")
          r.headers["Content-Disposition"].should eq("attachment; filename=\"Tests-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
          r.should render_template("api/events/index")
        end

        render_views

        before(:each) { Timecop.freeze }

        it "responds a csv for a given grouping" do
          DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :positive], error_code: 1234})
          DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :negative], error_code: 1234})
          DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :negative], error_code: 1234})

          refresh_index

          response = get :index, "", format: 'csv', group_by: 'test.assays.qualitative_result,test.error_code'

          check_csv response
          response.body.should eq("test.assays.qualitative_result,test.error_code,count\nnegative,1234,2\npositive,1234,1\n")
        end

        it "returns a csv with columns for a given grouping even when there are no assays" do
          get :index, "", format: 'csv', group_by: 'device.lab_user,test.error_code'
          response.body.should eq("device.lab_user,test.error_code,count\n")
        end
      end
    end

    context "Ordering" do
      it "should order by age" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :positive], patient_age: 20})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[qualitative_result: :negative], patient_age: 10})

        response = get_updates(order_by: :patient_age)

        response[0]["test"]["assays"].first["qualitative_result"].should eq("negative")
        response[0]["test"]["patient_age"].should eq(10)
        response[1]["test"]["assays"].first["qualitative_result"].should eq("positive")
        response[1]["test"]["patient_age"].should eq(20)
      end
    end

    context "Custom Fields" do
      it "should retrieve an test custom fields by uuid", context do
        Manifest.create! definition: %{{
          "metadata" : {
            "device_models" : ["#{device.device_model.name}"],
            "version" : 2,
            "api_version" : "#{Manifest::CURRENT_VERSION}",
            "source" : {"type" : "json"}
          },
          "custom_fields": {
            "test.foo": {
              "type": "string"
            }
          },
          "field_mapping" : {
            "test.foo" : {"lookup" : "some_field"}
          }
        }}
        DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(some_field: 1234)
        test = all_elasticsearch_tests.first["_source"]["test"]

        refresh_index

        response = get :custom_fields, id: test["uuid"]
        response.status.should eq(200)
        response = Oj.load response.body

        response["custom_fields"]["test"]["foo"].should eq(1234)
        response["uuid"].should eq(test["uuid"])
      end
    end

    context "PII" do
      it "should retrieve an test PII by uuid" do
        definition = %{{
          "metadata" : {
            "device_models" : ["#{device.device_model.name}"],
            "api_version" : "#{Manifest::CURRENT_VERSION}",
            "version" : "1.0.0",
            "source" : {"type" : "json"}
          },
          "custom_fields": {
            "patient.name": {
              "pii": true
            }
          },
          "field_mapping" : {
            "test.assays[*].qualitative_result": {
              "lookup" : "assays[*].qualitative_result"
            },
            "patient.name": {
              "lookup" : "patient_name"
            }
          }
        }}

        Manifest.create! definition: definition

        DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(assays: [qualitative_result: :positive], patient_name: "jdoe")
        test = all_elasticsearch_tests.first["_source"]["test"]

        refresh_index

        response = get :pii, id: test["uuid"]
        response.status.should eq(200)
        response = Oj.load response.body

        response["pii"]["patient"]["name"].should eq("jdoe")
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
