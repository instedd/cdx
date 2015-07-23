require 'spec_helper'

describe Api::MessagesController, elasticsearch: true, validate_manifest: false do

  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  let(:data)  {Oj.dump test: {assays: [qualitative_result: :positive]}}
  let(:datas) {Oj.dump [
    {test: {assays: [qualitative_result: :positive]}},
    {test: {assays: [qualitative_result: :negative]}}
  ]}
  before(:each) {sign_in user}

  def get_updates(options, body="")
    refresh_index
    response = get :index, body, options.merge(format: 'json')
    response.status.should eq(200)
    Oj.load(response.body)["tests"]
  end

  context "Creation" do

    it "should create message in the database" do
      response = post :create, data, device_id: device.uuid, authentication_token: device.plain_secret_key
      response.status.should eq(200)

      message = DeviceMessage.first
      message.device_id.should eq(device.id)
      message.raw_data.should_not eq(data)
      message.plain_text_data.should eq(data)
    end

    it "should create test in elasticsearch" do
      post :create, data, device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests.first["_source"]
      test["test"]["assays"].first["qualitative_result"].should eq("positive")
      test["test"]["reported_time"].should_not eq(nil)
      test["device"]["uuid"].should eq(device.uuid)
      TestResult.first.uuid.should eq(test["test"]["uuid"])
    end

    it "should create multiple tests in the database" do
      response = post :create, datas, device_id: device.uuid, authentication_token: device.plain_secret_key
      response.status.should eq(200)

      message = DeviceMessage.first
      message.device_id.should eq(device.id)
      message.raw_data.should_not eq(datas)
      message.plain_text_data.should eq(datas)

      TestResult.count.should eq(2)
    end

    it "should create multiple tests in elasticsearch" do
      post :create, datas, device_id: device.uuid, authentication_token: device.plain_secret_key

      tests = all_elasticsearch_tests
      tests.count.should eq(2)

      tests.map {|e| e["_source"]["test"]["assays"].first["qualitative_result"]}.should =~ ["positive", "negative"]

      TestResult.count.should eq(2)
      TestResult.pluck(:uuid).should =~ tests.map {|e| e["_source"]["test"]["uuid"]}
    end

    it "should store institution_id in elasticsearch" do
      post :create, data, device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests.first["_source"]
      test["institution"]["id"].should eq(device.institution_id)
    end

    it "should override test if test_id is the same" do
      post :create, Oj.dump(test: {id: "1234", patient_age: 20}), device_id: device.uuid, authentication_token: device.plain_secret_key

      TestResult.count.should eq(1)
      test = TestResult.first
      test.test_id.should eq("1234")

      Oj.load(DeviceMessage.first.plain_text_data)["test"]["patient_age"].should eq(20)

      tests = all_elasticsearch_tests
      tests.size.should eq(1)
      test = tests.first
      test["_source"]["test"]["id"].should eq("1234")
      test["_id"].should eq("#{device.uuid}_1234")
      test["_source"]["test"]["patient_age"].should eq(20)

      post :create, Oj.dump(test: {id: "1234", patient_age: 30}), device_id: device.uuid, authentication_token: device.plain_secret_key

      TestResult.count.should eq(1)
      test = TestResult.first
      test.test_id.should eq("1234")

      DeviceMessage.count.should eq(2)
      Oj.load(DeviceMessage.last.plain_text_data)["test"]["patient_age"].should eq(30)

      tests = all_elasticsearch_tests
      tests.size.should eq(1)
      test = tests.first
      test["_source"]["test"]["id"].should eq("1234")
      test["_id"].should eq("#{device.uuid}_1234")
      test["_source"]["test"]["patient_age"].should eq(30)

      a_device = Device.make(institution: institution)
      post :create, Oj.dump(test: {id: "1234", age: 20}), device_id: a_device.uuid, authentication_token: a_device.plain_secret_key

      TestResult.count.should eq(2)
      tests = all_elasticsearch_tests
      tests.size.should eq(2)
    end

    it "should generate a start_time date if it's not provided" do
      post :create, data, device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests.first["_source"]
      test["start_time"].should eq(test["created_at"])
    end

  end

  context "Manifest" do
    it "shouldn't store sensitive data in elasticsearch" do
      post :create, Oj.dump(test: {assays:[qualitative_result: :positive]}, patient: {id: 1234}), device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests.first["_source"]
      test["test"]["assays"].first["qualitative_result"].should eq("positive")
      test["test"]["reported_time"].should_not eq(nil)
      test["patient"]["id"].should eq(nil)
    end

    it "applies an existing manifest" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "test.name" : {"lookup" : "assay.name"},
          "patient.id" : {"lookup" : "patient_id"}
        }
      }}
      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests.first["_source"]
      test["test"]["name"].should eq("GX4002")
      test["test"]["reported_time"].should_not eq(nil)
      test["patient"]["id"].should be_nil
    end

    it "stores pii in the test according to manifest" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "custom_fields": [
          {"name": "patient.foo", "type": "integer", "pii": true}
        ],
        "field_mapping" : {
          "test.name" : {"lookup" : "assay.name"},
          "patient.foo" : {"lookup" : "patient_id"}
        }
      }}

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests.first["_source"]
      test["test"]["name"].should eq("GX4002")
      test["patient"]["id"].should be_nil
      test["patient"]["foo"].should be_nil

      test = TestResult.first
      raw_data = test.sensitive_data
      test.plain_sensitive_data.should_not eq(raw_data)
      test.plain_sensitive_data["patient"]["id"].should be_nil
      test.plain_sensitive_data["patient"]["foo"].should eq(1234)
      test.plain_sensitive_data["patient"]["foo"].should eq(1234)
    end

    it "merges pii from different tests in the same sample across devices" do
      device2 = Device.make institution_id: institution.id, device_model: device.device_model
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "custom_fields": [
          {
            "name": "patient.telephone_number",
            "type" : "integer",
            "pii" : true
          }
        ],
        "field_mapping" : {
          "test.name" : {"lookup" : "assay.name"},
          "sample.uid" :  {"lookup" : "sample_id"},
          "patient.id" : {"lookup" : "patient_id"},
          "patient.telephone_number" : {"lookup" : "patient_telephone_number"}
        }
      }}

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 3, sample_id: "10"), device_id: device.uuid, authentication_token: device.plain_secret_key
      post :create, Oj.dump(assay: {name: "GX4002"}, patient_telephone_number: 2222222, sample_id: 10), device_id: device2.uuid, authentication_token: device2.plain_secret_key

      TestResult.count.should eq(2)
      Sample.count.should eq(1)

      TestResult.first.sample.should eq(Sample.first)
      TestResult.last.sample.should eq(Sample.first)

      sample = Sample.first
      sample.plain_sensitive_data["sample"]["uid"].should eq(10)
      sample.patient.plain_sensitive_data["patient"]["id"].should eq(3)
      sample.patient.plain_sensitive_data["patient"]["telephone_number"].should eq(2222222)
    end

    it "uses the last version of the manifest" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 1,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "custom_fields" : [
          {"name": "test.foo"}
        ],
        "field_mapping" : {
          "test.foo" : {"lookup" : "assay.name"}
        }
      }}

      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 2,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "test.name" : {"lookup" : "assay.name"}
        }
      }}

      post :create, Oj.dump(assay: {name: "GX4002"}, patient_id: 1234), device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests.first["_source"]
      test["test"]["foo"].should be_nil
      test["test"]["name"].should eq("GX4002")
    end

    it "stores custom fields according to the manifest" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "version" : 2,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "custom_fields" : [
          {"name": "test.foo"}
        ],
        "field_mapping" : {
          "test.foo" : {"lookup" : "some_field"}
        }
      }}

      post :create, Oj.dump(some_field: 1234), device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests.first["_source"]
      test["test"]["foo"].should be_nil

      test = TestResult.first
      test.sample.should be_nil
      test.custom_fields["test"]["foo"].should eq(1234)
    end

    it "validates the data type" do
      Manifest.create! definition: %{{
        "metadata" : {
          "device_models" : ["#{device.device_model.name}"],
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "test.error_code" : {"lookup" : "error_code"}
        }
      }}
      post :create, Oj.dump(error_code: 1234), device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests.first["_source"]
      test["test"]["error_code"].should eq(1234)

      post :create, Oj.dump(error_code: "foo"), device_id: device.uuid, authentication_token: device.plain_secret_key

      response.code.should eq("422")
      Oj.load(response.body)["errors"].should eq("'foo' is not a valid value for 'test.error_code' (must be an integer)")
    end

    context "csv" do

      let!(:manifest) do Manifest.create! definition: %{
          {
            "metadata" : {
              "version" : "1",
              "api_version" : "#{Manifest::CURRENT_VERSION}",
              "device_models" : "#{device.device_model.name}",
              "source" : { "type" : "csv" }
            },
            "field_mapping" : {
              "test.error_code" : {"lookup" : "error_code"},
              "test.qualitative_result" : {"lookup" : "result"}
            }
          }
        }
      end

      it 'parses a single line csv' do
        csv = %{error_code;result\n0;positive}
        post :create, csv, device_id: device.uuid, authentication_token: device.plain_secret_key

        tests = all_elasticsearch_tests.sort_by { |test| test["_source"]["test"]["error_code"] }
        tests.count.should eq(1)
        test = tests.first["_source"]
        test["test"]["error_code"].should eq(0)
        test["test"]["qualitative_result"].should eq("positive")
      end

      it 'parses a multi line csv' do
        csv = %{error_code;result\n0;positive\n1;negative}
        post :create, csv, device_id: device.uuid, authentication_token: device.plain_secret_key

        tests = all_elasticsearch_tests.sort_by { |test| test["_source"]["test"]["error_code"] }
        tests.count.should eq(2)
        test = tests.first["_source"]
        test["test"]["error_code"].should eq(0)
        test["test"]["qualitative_result"].should eq("positive")
        test = tests.last["_source"]
        test["test"]["error_code"].should eq(1)
        test["test"]["qualitative_result"].should eq("negative")
      end
    end
  end
end
