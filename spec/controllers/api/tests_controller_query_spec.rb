require 'spec_helper'

describe Api::TestsController, elasticsearch: true, validate_manifest: false do

  let(:user) { User.make }
  let!(:institution) { Institution.make user_id: user.id }
  let(:site) { Site.make institution: institution }
  let(:device) { Device.make institution: institution, site: site }
  let(:data) { Oj.dump test:{assays: [result: :positive]} }
  before(:each) { sign_in user }

  def get_updates(options, body="")
    refresh_index
    response = get :index, body, options.merge(format: 'json')
    expect(response.status).to eq(200)
    Oj.load(response.body)["tests"]
  end

  context "Query" do
    context "Policies" do
      it "allows a user to query tests of it's own institutions" do
        device2 = Device.make

        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[{name: "mtb", result: :positive}]})
        DeviceMessage.create_and_process device: device2, plain_text_data: (Oj.dump test:{assays:[{name: "mtb", result: :negative}]})

        refresh_index

        response = get_updates 'test.assays.name' => 'mtb'

        expect(response.size).to eq(1)
        expect(response.first["test"]["assays"].first["result"]).to eq("positive")
      end

      context "Custom fields" do
        it "should retrieve an test custom fields when querying", context do
          device.manifest.update! definition: %{{
            "metadata" : {
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

          response = get_updates "id" => test["uuid"]
          expect(response.size).to eq(1)
          expect(response.first["test"]["custom_fields"]["foo"]).to eq(1234)
        end
      end
    end

    context "Filter" do
      let(:device2) {Device.make institution: institution}

      it "should check for new tests since a date" do
        Timecop.freeze(Time.utc(2013, 1, 1, 12, 0, 0))
        DeviceMessage.create_and_process device: device, plain_text_data: data
        Timecop.freeze(Time.utc(2013, 1, 2, 12, 0, 0))
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :negative]})

        response = get_updates('test.reported_time_since' => Time.utc(2013, 1, 2, 12, 0, 0).utc.iso8601)
        expect(response.size).to eq(1)
        expect(response.first["test"]["assays"].first["result"]).to eq("negative")

        response = get_updates('test.reported_time_since' => Time.utc(2013, 1, 1, 12, 0, 0).utc.iso8601)

        expect(response.first["test"]["assays"].first["result"]).to eq("positive")
        expect(response.last["test"]["assays"].first["result"]).to eq("negative")

        expect(get_updates('test.reported_time_since' => Time.utc(2013, 1, 3, 12, 0, 0).utc.iso8601)).to be_empty
      end

      it "filters by an analyzed result" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", result: :negative]})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", result: :positive]})

        response = get_updates('test.assays.result' => :positive)

        expect(response.size).to eq(1)
        expect(response.first["test"]["assays"].first["result"]).to eq("positive")
      end

      it "filters by name" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", result: :positive]})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "flu", result: :negative]})

        response = get_updates 'test.assays.name' => 'mtb'

        expect(response.size).to eq(1)
        expect(response.first["test"]["assays"].first["result"]).to eq("positive")
      end

      it "filters by test_id" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{id: 2, assays:[name: "mtb", result: :positive]})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "flu", result: :negative]})

        response = get_updates 'test.id' => 2

        expect(response.size).to eq(1)
        expect(response.first["test"]["assays"].first["result"]).to eq("positive")
      end

      it "filters by test type" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", result: :positive], type: :qc})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", result: :negative], type: :specimen})

        response = get_updates 'test.type' => :specimen

        expect(response.size).to eq(1)
        expect(response.first["test"]["assays"].first["result"]).to eq("negative")
      end

      it "filters for more than one value" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", result: :positive]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", result: :negative]}, patient: {gender: :female})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "flu", result: :negative]})

        response = get_updates('patient.gender' => [:male, :female]).sort_by do |test|
          test["test"]["assays"].first["result"]
        end

        expect(response.size).to eq(2)
        expect(response.first["test"]["assays"].first["result"]).to eq("negative")
        expect(response.last["test"]["assays"].first["result"]).to eq("positive")
      end
    end

    context "Grouping" do
      it "groups by gender in query params" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :positive]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :negative]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :negative]}, patient: {gender: :female})

        response = get_updates(group_by: 'patient.gender').sort_by do |test|
          test["patient.gender"]
        end

        expect(response).to eq([
          {"patient.gender"=>"female", "count"=>1},
          {"patient.gender"=>"male", "count"=>2}
        ])
      end

      it "groups by gender and result in post body" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :positive]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :negative]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :negative]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :positive]}, patient: {gender: :female})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :positive]}, patient: {gender: :female})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :negative]}, patient: {gender: :female})

        response = get_updates({}, Oj.dump(group_by: ['patient.gender', 'test.assays.result'])).sort_by do |test|
          test["patient.gender"] + test["test.assays.result"]
        end

        expect(response).to eq([
          {"patient.gender"=>"female", "test.assays.result" => "negative", "count"=>1},
          {"patient.gender"=>"female", "test.assays.result" => "positive", "count"=>2},
          {"patient.gender"=>"male", "test.assays.result" => "negative", "count"=>2},
          {"patient.gender"=>"male", "test.assays.result" => "positive", "count"=>1}
        ])
      end

      it "groups and filters for more than one value" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", result: :positive]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", result: :positive]}, patient: {gender: :male})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "mtb", result: :negative]}, patient: {gender: :female})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[name: "flu", result: :negative]})

        response = get_updates("page_size"=>0, "group_by"=>["patient.gender"], "patient.gender"=>["male", "female"]).sort_by do |test|
          test["patient.gender"]
        end

        expect(response).to eq([
          {"patient.gender"=>"female", "count"=>1},
          {"patient.gender"=>"male", "count"=>2}
        ])
      end

      context "CSV" do
        def check_csv(r)
          expect(r.status).to eq(200)
          expect(r.content_type).to eq("text/csv")
          expect(r.headers["Content-Disposition"]).to eq("attachment; filename=\"Tests-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
          expect(r).to render_template("api/tests/index")
        end

        render_views

        before(:each) { Timecop.freeze }

        it "responds a csv for a given grouping" do
          DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :positive], error_code: 1234})
          DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :negative], error_code: 1234})
          DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :negative], error_code: 1234})

          refresh_index

          response = get :index, "", format: 'csv', group_by: 'test.assays.result,test.error_code'

          check_csv response
          expect(response.body).to eq("test.assays.result,test.error_code,count\nnegative,1234,2\npositive,1234,1\n")
        end

        it "returns a csv with columns for a given grouping even when there are no assays" do
          get :index, "", format: 'csv', group_by: 'test.site_user,test.error_code'
          expect(response.body).to eq("test.site_user,test.error_code,count\n")
        end
      end
    end

    context "Ordering" do
      it "should order by age" do
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :positive]}, encounter: {patient_age: {"years" => 20}})
        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :negative]}, encounter: {patient_age: {"years" => 10}})

        response = get_updates(order_by: "encounter.patient_age")

        expect(response[0]["test"]["assays"].first["result"]).to eq("negative")
        expect(response[0]["encounter"]["patient_age"]["years"]).to eq(10)
        expect(response[1]["test"]["assays"].first["result"]).to eq("positive")
        expect(response[1]["encounter"]["patient_age"]["years"]).to eq(20)
      end
    end

    context "PII" do
      before(:each) do
        definition = %{{
          "metadata" : {
            "api_version" : "#{Manifest::CURRENT_VERSION}",
            "version" : "1.0.0",
            "source" : {"type" : "json"}
          },
          "custom_fields": {
          },
          "field_mapping" : {
            "test.assays.result": {
              "lookup" : "assays.result"
            },
            "patient.name": {
              "lookup" : "patient_name"
            }
          }
        }}

        device.manifest.update! definition: definition

        DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(assays: [result: :positive], patient_name: "jdoe")
        refresh_index
      end

      let(:test) { TestResult.first }

      it "should retrieve a test PII by uuid" do
        response = get :pii, id: test.uuid
        expect(response.status).to eq(200)
        response = Oj.load response.body

        expect(response["pii"]["patient"]["name"]).to eq("jdoe")
        expect(response["uuid"]).to eq(test["uuid"])
      end

      context "permissions" do

        it "should not return pii if unauthorised" do
          other_user = User.make
          grant user, other_user, { testResult: institution }, Policy::Actions::QUERY_TEST
          sign_in other_user
          get :pii, id: test.uuid

          expect(response).to be_forbidden
        end

        it "should return pii if unauthorised" do
          other_user = User.make
          grant user, other_user, { testResult: institution }, Policy::Actions::PII_TEST
          sign_in other_user
          get :pii, id: test.uuid

          expect(response).to be_success
        end
      end
    end

    context "Schema" do

      it "should return test schema" do
        allow_any_instance_of(TestsSchema).to receive(:build).and_return('a schema definition')
        response = get :schema, locale: "es-AR", format: 'json'

        response_schema = Oj.load response.body
        expect(response_schema).to eq('a schema definition')
      end

    end
  end
end
