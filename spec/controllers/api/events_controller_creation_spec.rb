require 'spec_helper'

describe Api::EventsController, elasticsearch: true, validate_manifest: false do

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
    Oj.load(response.body)["tests"]
  end

  context "Creation" do

    it "should create event in the database" do
      response = post :create, data, device_id: device.uuid, authentication_token: device.secret_key
      response.status.should eq(200)

      event = DeviceEvent.first
      event.device_id.should eq(device.id)
      event.raw_data.should_not eq(data)
      event.plain_text_data.should eq(data)
    end

    it "should create test in elasticsearch" do
      post :create, data, device_id: device.uuid, authentication_token: device.secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["results"].first["result"].should eq("positive")
      test["created_at"].should_not eq(nil)
      test["device_uuid"].should eq(device.uuid)
      TestResult.first.uuid.should eq(test["uuid"])
    end

    it "should create multiple tests in the database" do
      response = post :create, datas, device_id: device.uuid, authentication_token: device.secret_key
      response.status.should eq(200)

      event = DeviceEvent.first
      event.device_id.should eq(device.id)
      event.raw_data.should_not eq(datas)
      event.plain_text_data.should eq(datas)

      TestResult.count.should eq(2)
    end

    it "should create multiple tests in elasticsearch" do
      post :create, datas, device_id: device.uuid, authentication_token: device.secret_key

      tests = all_elasticsearch_tests_for(institution)
      tests.count.should eq(2)

      tests.map {|e| e["_source"]["results"].first["result"]}.should =~ ["positive", "negative"]

      TestResult.count.should eq(2)
      TestResult.pluck(:uuid).should =~ tests.map {|e| e["_source"]["uuid"]}
    end

    it "should store institution_id in elasticsearch" do
      post :create, data, device_id: device.uuid, authentication_token: device.secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["institution_id"].should eq(device.institution_id)
    end

    it "should override test if test_id is the same" do
      post :create, Oj.dump(test_id: "1234", age: 20), device_id: device.uuid, authentication_token: device.secret_key

      TestResult.count.should eq(1)
      test = TestResult.first
      test.test_id.should eq("1234")

      Oj.load(DeviceEvent.first.plain_text_data)["age"].should eq(20)

      tests = all_elasticsearch_tests_for(institution)
      tests.size.should eq(1)
      test = tests.first
      test["_source"]["test_id"].should eq("1234")
      test["_id"].should eq("#{device.uuid}_1234")
      test["_source"]["age"].should eq(20)

      post :create, Oj.dump(test_id: "1234", age: 30), device_id: device.uuid, authentication_token: device.secret_key

      TestResult.count.should eq(1)
      test = TestResult.first
      test.test_id.should eq("1234")

      DeviceEvent.count.should eq(2)
      Oj.load(DeviceEvent.last.plain_text_data)["age"].should eq(30)

      tests = all_elasticsearch_tests_for(institution)
      tests.size.should eq(1)
      test = tests.first
      test["_source"]["test_id"].should eq("1234")
      test["_id"].should eq("#{device.uuid}_1234")
      test["_source"]["age"].should eq(30)

      a_device = Device.make(institution: institution)
      post :create, Oj.dump(test_id: "1234", age: 20), device_id: a_device.uuid, authentication_token: a_device.secret_key

      TestResult.count.should eq(2)
      tests = all_elasticsearch_tests_for(institution)
      tests.size.should eq(2)
    end

    it "should generate a start_time date if it's not provided" do
      post :create, data, device_id: device.uuid, authentication_token: device.secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["start_time"].should eq(test["created_at"])
    end

  end

  context "Manifest" do
    it "shouldn't store sensitive data in elasticsearch" do
      post :create, Oj.dump(results:[result: :positive], patient_id: 1234), device_id: device.uuid, authentication_token: device.secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["results"].first["result"].should eq("positive")
      test["created_at"].should_not eq(nil)
      test["patient_id"].should eq(nil)
    end

    it "applies an existing manifest" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "1.1.0",
          "source" : {"type" : "json"}
        },
        "field_mapping" : { "test" : [{
          "target_field" : "assay_name",
          "source" : {"lookup" : "assay.name"},
          "type" : "string",
          "core" : true
        }]}
      }}
      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_id: device.uuid, authentication_token: device.secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["assay_name"].should eq("GX4002")
      test["created_at"].should_not eq(nil)
      test["patient_id"].should be_nil
    end

    it "stores pii in the test according to manifest" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "1.1.0",
          "source" : {"type" : "json"}
        },
        "field_mapping" : {"test" : [
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

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_id: device.uuid, authentication_token: device.secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["assay_name"].should eq("GX4002")
      test["patient_id"].should eq(nil)
      test["foo"].should be_nil

      test = TestResult.first
      raw_data = test.sensitive_data
      test.plain_sensitive_data.should_not eq(raw_data)
      test.plain_sensitive_data["patient_id"].should be_nil
      test.plain_sensitive_data["foo"].should eq(1234)
      test.plain_sensitive_data[:foo].should eq(1234)
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
          "test" : [
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

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 3, sample_id: "10"), device_id: device.uuid, authentication_token: device.secret_key
      post :create, Oj.dump(assay: {name: "GX4002"}, patient_telephone_number: 2222222, sample_id: 10), device_id: device2.uuid, authentication_token: device2.secret_key

      TestResult.count.should eq(2)
      Sample.count.should eq(1)

      TestResult.first.sample.should eq(Sample.first)
      TestResult.last.sample.should eq(Sample.first)

      sample = Sample.first
      sample.plain_sensitive_data["sample_uid"].should eq(10)
      sample.patient.plain_sensitive_data["patient_id"].should eq(3)
      sample.patient.plain_sensitive_data["patient_telephone_number"].should eq(2222222)
    end

    it "uses the last version of the manifest" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "1.1.0",
          "source" : {"type" : "json"}
        },
        "field_mapping" : { "test" : [
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
        "field_mapping" : { "test" : [
          {
            "target_field" : "assay_name",
            "source" : {"lookup" : "assay.name"},
            "type" : "string",
            "core" : true
          }
        ]}
      }}

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_id: device.uuid, authentication_token: device.secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["foo"].should be_nil
      test["assay_name"].should eq("GX4002")
    end

    it "stores custom fields according to the manifest" do
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

      post :create, Oj.dump(some_field: 1234), device_id: device.uuid, authentication_token: device.secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["foo"].should be_nil

      test = TestResult.first
      test.sample.should be_nil
      test.custom_fields[:foo].should eq(1234)
      test.custom_fields["foo"].should eq(1234)
    end

    it "validates the data type" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "api_version" : "1.1.0",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : { "test" : [{
            "target_field" : "error_code",
            "source" : {"lookup" : "error_code"},
            "core" : true,
            "type" : "integer"
          }]}
      }}
      post :create, Oj.dump(error_code: 1234), device_id: device.uuid, authentication_token: device.secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["error_code"].should eq(1234)

      post :create, Oj.dump(error_code: "foo"), device_id: device.uuid, authentication_token: device.secret_key

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
            "field_mapping" : { "test" : [{
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
        post :create, csv, device_id: device.uuid, authentication_token: device.secret_key

        tests = all_elasticsearch_tests_for(institution).sort_by { |test| test["_source"]["error_code"] }
        tests.count.should eq(1)
        test = tests.first["_source"]
        test["error_code"].should eq(0)
        test["result"].should eq("positive")
      end

      it 'parses a multi line csv' do
        csv = %{error_code;result\n0;positive\n1;negative}
        post :create, csv, device_id: device.uuid, authentication_token: device.secret_key

        tests = all_elasticsearch_tests_for(institution).sort_by { |test| test["_source"]["error_code"] }
        tests.count.should eq(2)
        test = tests.first["_source"]
        test["error_code"].should eq(0)
        test["result"].should eq("positive")
        test = tests.last["_source"]
        test["error_code"].should eq(1)
        test["result"].should eq("negative")
      end
    end
  end
end
