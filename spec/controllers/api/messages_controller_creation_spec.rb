require 'spec_helper'

describe Api::MessagesController, elasticsearch: true, validate_manifest: false do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
    @site = Site.make! institution: @institution
    @device = Device.make! institution: @institution, site: @site
  end
  let(:data)  {Oj.dump test: {assays: [result: :positive]}}
  let(:datas) {Oj.dump [
    {test: {assays: [result: :positive]}},
    {test: {assays: [result: :negative]}}
  ]}
  before(:each) {sign_in user}

  context "Creation" do

    it "should create message in the database" do
      response = post :create, body: data, params: { device_id: device.uuid, authentication_token: device.plain_secret_key }
      expect(response.status).to eq(200)

      message = DeviceMessage.first
      expect(message.device_id).to eq(device.id)
      expect(message.raw_data).not_to eq(data)
      expect(message.plain_text_data).to eq(data)
    end

    it "should create test in elasticsearch" do
      post :create, body: data, params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      test = all_elasticsearch_tests.first["_source"]
      expect(test["test"]["assays"].first["result"]).to eq("positive")
      expect(test["test"]["reported_time"]).not_to eq(nil)
      expect(test["device"]["uuid"]).to eq(device.uuid)
      expect(TestResult.first.uuid).to eq(test["test"]["uuid"])
    end

    it "should create multiple tests in the database" do
      response = post :create, body: datas, params: { device_id: device.uuid, authentication_token: device.plain_secret_key }
      expect(response.status).to eq(200)

      message = DeviceMessage.first
      expect(message.device_id).to eq(device.id)
      expect(message.raw_data).not_to eq(datas)
      expect(message.plain_text_data).to eq(datas)

      expect(TestResult.count).to eq(2)
    end

    it "should create multiple tests in elasticsearch" do
      post :create, body: datas, params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      tests = all_elasticsearch_tests
      expect(tests.count).to eq(2)

      expect(tests.map {|e| e["_source"]["test"]["assays"].first["result"]}).to match_array(["positive", "negative"])

      expect(TestResult.count).to eq(2)
      expect(TestResult.pluck(:uuid)).to match_array(tests.map {|e| e["_source"]["test"]["uuid"]})
    end

    it "should store institution uuid in elasticsearch" do
      post :create, body: data, params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      test = all_elasticsearch_tests.first["_source"]
      expect(test["institution"]["uuid"]).to eq(device.institution.uuid)
    end

    it "should override test if test_id is the same" do
      post :create,
        body: Oj.dump(test: {id: "1234"}, encounter: {patient_age: {"years" => 20}}),
        params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      expect(TestResult.count).to eq(1)
      test = TestResult.first
      expect(test.test_id).to eq("1234")

      expect(Oj.load(DeviceMessage.first.plain_text_data)["encounter"]["patient_age"]["years"]).to eq(20)

      tests = all_elasticsearch_tests
      expect(tests.size).to eq(1)
      test = tests.first
      expect(test["_source"]["test"]["id"]).to eq("1234")
      expect(test["_id"]).to eq(test["_source"]["test"]["uuid"])
      expect(test["_source"]["encounter"]["patient_age"]["years"]).to eq(20)

      post :create,
        body: Oj.dump(test: {id: "1234"}, encounter: {patient_age: {"years" => 30}}),
        params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      expect(TestResult.count).to eq(1)
      test = TestResult.first
      expect(test.test_id).to eq("1234")

      expect(DeviceMessage.count).to eq(2)
      expect(Oj.load(DeviceMessage.last.plain_text_data)["encounter"]["patient_age"]["years"]).to eq(30)

      tests = all_elasticsearch_tests
      expect(tests.size).to eq(1)
      test = tests.first
      expect(test["_source"]["test"]["id"]).to eq("1234")
      expect(test["_id"]).to eq(test["_source"]["test"]["uuid"])
      expect(test["_source"]["encounter"]["patient_age"]["years"]).to eq(30)

      a_device = Device.make!(institution: institution)
      post :create,
        body: Oj.dump(test: {id: "1234", age: {"years" => 20}}),
        params: { device_id: a_device.uuid, authentication_token: a_device.plain_secret_key }

      expect(TestResult.count).to eq(2)
      tests = all_elasticsearch_tests
      expect(tests.size).to eq(2)
    end

    it "should generate a start_time date if it's not provided" do
      post :create,
        body: data,
        params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      test = all_elasticsearch_tests.first["_source"]
      expect(test["start_time"]).to eq(test["created_at"])
    end

  end

  context "Manifest" do
    it "shouldn't store sensitive data in elasticsearch" do
      post :create,
        body: Oj.dump(test: {assays:[result: :positive]}, patient: { id: 1234 }),
        params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      test = all_elasticsearch_tests.first["_source"]
      expect(test["test"]["assays"].first["result"]).to eq("positive")
      expect(test["test"]["reported_time"]).not_to eq(nil)
      expect(test["patient"]["id"]).to eq(nil)
    end

    it "applies an existing manifest" do
      manifest = device.manifest
      manifest.definition = %{{
        "metadata" : {
          "version" : 1,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "test.name" : {"lookup" : "assay.name"},
          "patient.id" : {"lookup" : "patient_id"}
        }
      }}
      manifest.save
      post :create,
        body: Oj.dump(assay: {name: "GX4002"}, patient_id: 1234),
        params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      test = all_elasticsearch_tests.first["_source"]
      expect(test["test"]["name"]).to eq("GX4002")
      expect(test["test"]["reported_time"]).not_to eq(nil)
      expect(test["patient"]["id"]).to be_nil
    end

    it "stores pii in the test according to manifest" do
      device.manifest.update! definition: %{{
        "metadata" : {
          "version" : 1,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "custom_fields": {
          "patient.foo": {"pii": true}
        },
        "field_mapping" : {
          "test.name" : {"lookup" : "assay.name"},
          "patient.foo" : {"lookup" : "patient_id"}
        }
      }}

      post :create,
        body: Oj.dump(assay: {name: "GX4002"}, patient_id: "1234"),
        params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      test = all_elasticsearch_tests.first["_source"]
      expect(test["test"]["name"]).to eq("GX4002")
      expect(test["patient"]['uuid']).to eq(Patient.first.uuid)

      test = TestResult.first
      raw_data = test.sensitive_data
      expect(test.plain_sensitive_data).not_to eq(raw_data)
      expect(test.patient.plain_sensitive_data["id"]).to be_nil
      expect(test.patient.plain_sensitive_data["custom"]['foo']).to eq("1234")
    end

    it "merges pii from different tests in the same sample across devices" do
      device2 = Device.make! institution: institution, device_model: device.device_model, site: site
      device.manifest.update! definition: %{{
        "metadata" : {
          "version" : 1,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "custom_fields": {
          "patient.telephone_number": {
            "pii" : true
          }
        },
        "field_mapping" : {
          "test.name" : {"lookup" : "assay.name"},
          "sample.id" :  {"lookup" : "sample_id"},
          "patient.id" : {"lookup" : "patient.id"},
          "patient.telephone_number" : {"lookup" : "patient.telephone_number"}
        }
      }}

      post :create,
        body: Oj.dump(assay: {name: "GX4002"}, patient: {id: 3}, sample_id: "10"),
        params: { device_id: device.uuid, authentication_token: device.plain_secret_key }
      post :create,
        body: Oj.dump(assay: {name: "GX4002"}, patient: {telephone_number: "2222222"}, sample_id: 10),
        params: { device_id: device2.uuid, authentication_token: device2.plain_secret_key }

      expect(TestResult.count).to eq(2)
      expect(Sample.count).to eq(1)

      expect(TestResult.first.sample).to eq(Sample.first)
      expect(TestResult.last.sample).to eq(Sample.first)

      sample = Sample.first

      expect(sample.patient.plain_sensitive_data["id"]).to eq(3)
      expect(sample.patient.plain_sensitive_data['custom']["telephone_number"]).to eq("2222222")
    end

    it "uses the last version of the manifest" do
      device.manifest.update! definition: %{{
        "metadata" : {
          "version" : 1,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "custom_fields" : {
          "test.foo": {}
        },
        "field_mapping" : {
          "test.foo" : {"lookup" : "assay.name"}
        }
      }}

      device.manifest.update! definition: %{{
        "metadata" : {
          "version" : 2,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "test.name" : {"lookup" : "assay.name"}
        }
      }}

      post :create,
        body: Oj.dump(assay: {name: "GX4002"}, patient_id: 1234),
        params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      test = all_elasticsearch_tests.first["_source"]
      expect(test["test"]["foo"]).to be_nil
      expect(test["test"]["name"]).to eq("GX4002")
    end

    it "stores custom fields according to the manifest" do
      device.manifest.update! definition: %{{
        "metadata" : {
          "version" : 2,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "source" : {"type" : "json"}
        },
        "custom_fields" : {
          "test.foo" : {}
        },
        "field_mapping" : {
          "test.foo" : {"lookup" : "some_field"}
        }
      }}

      post :create,
        body: Oj.dump(some_field: 1234),
        params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      test = all_elasticsearch_tests.first["_source"]
      expect(test["test"]["foo"]).to be_nil

      test = TestResult.first
      expect(test.sample).to be_nil
      expect(test.custom_fields["foo"]).to eq(1234)
    end

    it "validates the data type" do
      device.manifest.update! definition: %{{
        "metadata" : {
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "test.error_code" : {"lookup" : "error_code"}
        }
      }}
      post :create,
        body: Oj.dump(error_code: 1234),
        params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      test = all_elasticsearch_tests.first["_source"]
      expect(test["test"]["error_code"]).to eq(1234)

      post :create,
        body: Oj.dump(error_code: "foo"),
        params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

      expect(response.code).to eq("422")
      expect(Oj.load(response.body)["errors"]).to eq("'foo' is not a valid value for 'test.error_code' (must be an integer)")
    end

    context "csv" do

      let!(:manifest) do
        device.manifest.update! definition: %{
          {
            "metadata" : {
              "version" : "1",
              "api_version" : "#{Manifest::CURRENT_VERSION}",
              "source" : { "type" : "csv" }
            },
            "field_mapping" : {
              "test.error_code" : {"lookup" : "error_code"},
              "test.assays.result" : {"lookup" : "result"}
            }
          }
        }
      end

      it 'parses a single line csv' do
        csv = %{error_code;result\n0;positive}
        post :create, body: csv, params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

        tests = all_elasticsearch_tests.sort_by { |test| test["_source"]["test"]["error_code"] }
        expect(tests.count).to eq(1)
        test = tests.first["_source"]
        expect(test["test"]["error_code"]).to eq(0)
        expect(test["test"]["assays"].first["result"]).to eq("positive")
      end

      it 'parses a multi line csv' do
        csv = %{error_code;result\n0;positive\n1;negative}
        post :create, body: csv, params: { device_id: device.uuid, authentication_token: device.plain_secret_key }

        tests = all_elasticsearch_tests.sort_by { |test| test["_source"]["test"]["error_code"] }
        expect(tests.count).to eq(2)
        test = tests.first["_source"]
        expect(test["test"]["error_code"]).to eq(0)
        expect(test["test"]["assays"].first["result"]).to eq("positive")
        test = tests.last["_source"]
        expect(test["test"]["error_code"]).to eq(1)
        expect(test["test"]["assays"].first["result"]).to eq("negative")
      end
    end
  end
end
