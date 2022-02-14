require "spec_helper"

describe DeviceMessageProcessor, elasticsearch: true do
  TEST_ID   = "4"
  TEST_ID_2 = "5"
  TEST_ID_3 = "6"

  TEST_RAW_RESULT         = "positivo 15%"
  TEST_CONCENTRATION      = "15%"
  TEST_START_TIME         = "2000-01-01T10:00:00"

  SAMPLE_ID               = "4002"
  SAMPLE_DATAGRAM         = "010100011100"
  SAMPLE_CULTURE_DAYS     = "10"
  SAMPLE_TYPE             = "sputum"
  SAMPLE_COLLECTION_DATE  = "2000-01-01T09:00:00"
  SAMPLE_PII_FIELDS       = {}.freeze
  SAMPLE_CORE_FIELDS      = {"id" => SAMPLE_ID, "type" => SAMPLE_TYPE, "collection_date" => SAMPLE_COLLECTION_DATE}.freeze
  SAMPLE_CUSTOM_FIELDS    = {"datagram" => SAMPLE_DATAGRAM, "culture_days" => SAMPLE_CULTURE_DAYS}.freeze

  PATIENT_ID              = "8000"
  PATIENT_GENDER          = "male"
  PATIENT_DOB             = "2000-01-01"
  PATIENT_SHIRT_COLOR     = "blue"
  PATIENT_HIV             = "positive"
  PATIENT_PII_FIELDS      = {"id" => PATIENT_ID, "dob" => PATIENT_DOB}.freeze
  PATIENT_CORE_FIELDS     = {"gender" => PATIENT_GENDER}.freeze
  PATIENT_CUSTOM_FIELDS   = {"shirt_color" => PATIENT_SHIRT_COLOR, "hiv" => PATIENT_HIV}.freeze

  ENCOUNTER_ID            = "1234"
  ENCOUNTER_CORE_FIELDS   = {"id" => ENCOUNTER_ID, "patient_age" => {"years" => 20}}.freeze
  ENCOUNTER_PII_FIELDS    = {}.freeze
  ENCOUNTER_CUSTOM_FIELDS = {"time" => "2001-01-01T10:00:00"}.freeze

  def parsed_message(test_id, params={})
    {
      "test" => {
        "core" => {
          "id" => test_id,
          "start_time" => @check_invalid_test == nil ? TEST_START_TIME : Time.now+1.day,
          "assays" => [
            { "name" => "mtb", "condition" => "mtb", "result" => "positive"}
          ]
        },
        "custom" => {
          "raw_result" => TEST_RAW_RESULT,
          "concentration" => TEST_CONCENTRATION
        }
      },
      "sample" => {
        "core" => SAMPLE_CORE_FIELDS.dup,
        "custom" => SAMPLE_CUSTOM_FIELDS.dup,
        "pii" => SAMPLE_PII_FIELDS.dup
      },
      "patient" => {
        "core" => PATIENT_CORE_FIELDS.dup,
        "pii" => PATIENT_PII_FIELDS.dup,
        "custom" => PATIENT_CUSTOM_FIELDS.dup,
      },
      "encounter" => {
        "core" => ENCOUNTER_CORE_FIELDS.dup,
        "pii" => ENCOUNTER_PII_FIELDS.dup,
        "custom" => ENCOUNTER_CUSTOM_FIELDS.dup,
      }
    }.deep_merge(params)
  end

  def result(assay, condition, result)
    {"name" => assay, "result" => result, "condition" => condition}
  end

  def clear(message, *scopes)
    scopes.each do |scope|
      message[scope]["pii"] = {}
      message[scope]["custom"] = {}
      message[scope]["core"] = {}
    end
  end

  let(:institution) {Institution.make!(kind: 'institution')}

  let(:site) {Site.make!(institution: institution, location_geoid: 'ne:ARG_1300')}

  let(:device) {Device.make!(institution: institution, site: site)}

  let(:device_message) do
    device_message = DeviceMessage.new(device: device, plain_text_data: '{}')
    allow(device_message).to receive(:parsed_messages).and_return([parsed_message(TEST_ID)])
    device_message.save!
    device_message
  end

  let(:device_message_processor) {DeviceMessageProcessor.new(device_message)}

  def assert_sample_data(sample)
    expect(sample.plain_sensitive_data).to eq(SAMPLE_PII_FIELDS)
    expect(sample.custom_fields).to eq(SAMPLE_CUSTOM_FIELDS)
    expect(sample.core_fields).to eq(SAMPLE_CORE_FIELDS)
  end

  def assert_patient_data(patient)
    expect(patient.plain_sensitive_data).to eq(PATIENT_PII_FIELDS)
    expect(patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS)
    expect(patient.core_fields).to eq(PATIENT_CORE_FIELDS)
  end

  def assert_test_data(test, additional_core_fields={}, additional_custom_fields={})
    expect(test.core_fields).to eq({"id"=>"4", "start_time"=>TEST_START_TIME, "assays"=>[{"name"=>"mtb", "condition"=>"mtb", "result"=>"positive"}]}.merge(additional_core_fields))
    expect(test.custom_fields).to eq({"raw_result" => TEST_RAW_RESULT, "concentration" => TEST_CONCENTRATION}.merge(additional_custom_fields))
  end

  def assert_test_relations(test)
    expect(test.device_id).to eq(device.id)
    expect(test.site_id).to eq(device.site.id)
    expect(test.institution_id).to eq(device.site.institution.id)
  end

  it "should create a test result" do
    device_message_processor.process

    expect(TestResult.count).to eq(1)
    test = TestResult.first
    expect(test.test_id).to eq(TEST_ID)
    assert_test_data(test)
    assert_test_relations(test)
  end

  it "should create a sample" do
    device_message_processor.process

    expect(Sample.count).to eq(1)
    sample = Sample.first
    expect(sample.sample_identifiers.first.entity_id).to eq(SAMPLE_ID)
    assert_sample_data(sample)
  end

  it "should create an encounter" do
    device_message_processor.process

    expect(Encounter.count).to eq(1)
    encounter = Encounter.first
    expect(encounter.entity_id).to eq(ENCOUNTER_ID)
    expect(encounter.core_fields.except("start_time", "end_time")).to eq(ENCOUNTER_CORE_FIELDS)
    expect(Time.parse(encounter.core_fields["start_time"]).at_beginning_of_day).to eq(Time.parse(TEST_START_TIME).at_beginning_of_day)
    expect(Time.parse(encounter.core_fields["end_time"]).at_beginning_of_day).to eq(Time.parse(TEST_START_TIME).at_beginning_of_day)
    expect(encounter.plain_sensitive_data).to eq(ENCOUNTER_PII_FIELDS)
    expect(encounter.custom_fields).to eq(ENCOUNTER_CUSTOM_FIELDS)
  end

  it "should create a patient" do
    device_message_processor.process

    expect(Patient.count).to eq(1)
    patient = Patient.first
    expect(patient.entity_id_hash).to eq(MessageEncryption.hash PATIENT_ID)
    assert_patient_data(patient)
  end

  it "should not update existing tests on new sample" do
    expect(device_message_processor.client).to receive(:bulk).never
    device_message_processor.process
  end

  it "should create multiple test results with single sample" do
    allow(device_message).to receive(:parsed_messages).and_return([parsed_message(TEST_ID), parsed_message(TEST_ID_2), parsed_message(TEST_ID_3)])
    device_message_processor.process

    expect(Sample.count).to eq(1)

    expect(TestResult.count).to eq(3)
    expect(TestResult.pluck(:test_id)).to match_array([TEST_ID, TEST_ID_2, TEST_ID_3])
    expect(TestResult.all.map(&:sample).map(&:id)).to eq([Sample.first.id] * 3)

    expect(all_elasticsearch_tests.map {|e| e['_source']['sample']['uuid']}).to eq([Sample.first.uuids] * 3)
  end

  it "should create multiple test results with a single request to the location service" do
    allow(device_message).to receive(:parsed_messages).and_return([parsed_message(TEST_ID), parsed_message(TEST_ID_2), parsed_message(TEST_ID_3)])

    LocationService.reload!

    stub = stub_request(:get, "http://locations.instedd.org/details?ancestors=true&id=ne:ARG_1300").
      to_return(:status => 200, :body => '[{"id":"ne:ARG_1300","name":"Catamarca","type":"Province","ancestorsIds":["ne:ARG"],"ancestors":[{"id":"ne:ARG","name":"Argentina","type":"Sovereign country","level":0,"lat":0,"lng":0,"set":""}],"level":1,"lat":-27.649319756801297,"lng":-67.51184361556845,"set":"ne"}]', :headers => {})

    device_message_processor.process

    expect(stub).to have_been_requested.at_most_once

    expect(Sample.count).to eq(1)
    expect(TestResult.count).to eq(3)
  end

  it "should index an encounter" do
    device_message_processor.process

    results = all_elasticsearch_encounters
    expect(results.length).to eq(1)

    result = results.first
    expect(result["_source"]["encounter"]["id"]).to eq(ENCOUNTER_ID)
    expect(result["_source"]["encounter"]["custom_fields"]["time"]).to eq(ENCOUNTER_CUSTOM_FIELDS["time"])
    expect(result["_source"]["patient"]["gender"]).to eq(PATIENT_GENDER)
  end

  context "sample identification" do

    let(:sample_created_at) { DateTime.now }

    let(:patient) do
      Patient.make!(
        uuid: 'def', institution: device_message.institution,
        core_fields: PATIENT_CORE_FIELDS,
        plain_sensitive_data: {"id" => PATIENT_ID},
      )
    end

    let(:sample) do
      Sample.make!(
        institution: device_message.institution, patient: patient,
        core_fields: {"type" => "blood"},
        created_at: sample_created_at
      )
    end

    let(:sample_identifier) do
      SampleIdentifier.make!(
        sample: sample,
        uuid: 'abc',
        entity_id: SAMPLE_ID,
        site: site,
        created_at: sample_created_at
      )
    end

    it "should update sample data and existing test results on new test result" do
      TestResult.create_and_index test_id: TEST_ID_2, sample_identifier: sample_identifier, patient: patient, device: device
      TestResult.create_and_index test_id: TEST_ID_3, sample_identifier: sample_identifier, patient: patient, device: device
      expect(TestResult.count).to eq(2)

      refresh_index

      device_message_processor.process

      expect(Sample.count).to eq(1)
      expect(Patient.count).to eq(1)
      expect(TestResult.count).to eq(3)
      sample = Sample.first
      assert_sample_data(sample)
      assert_patient_data(sample.patient)

      tests = all_elasticsearch_tests
      expect(tests.size).to eq(3)
      expect(tests.map { |test| test["_source"]["sample"]["type"] }).to eq([SAMPLE_TYPE] * 3)
    end

    it "should update sample data and existing test results on test result update" do
      TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, patient: patient, device: device
      TestResult.create_and_index test_id: TEST_ID_2, sample_identifier: sample_identifier, patient: patient, device: device

      refresh_index

      device_message_processor.process

      expect(Sample.count).to eq(1)
      expect(Patient.count).to eq(1)
      sample = Sample.first
      assert_sample_data(sample)
      assert_patient_data(sample.patient)

      tests = all_elasticsearch_tests
      expect(tests.map { |test| test["_source"]["sample"]["type"] }).to eq([SAMPLE_TYPE] * 2)
    end

    it "should not update existing tests if sample data indexed fields did not change" do
      TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, patient: patient, device: device
      TestResult.create_and_index test_id: TEST_ID_2, sample_identifier: sample_identifier, patient: patient, device: device

      refresh_index

      expect(device_message_processor.client).to receive(:bulk).never
      device_message_processor.process

      expect(Sample.count).to eq(1)
      expect(Patient.count).to eq(1)
      sample = Sample.first
      assert_sample_data(sample)
      assert_patient_data(sample.patient)
    end

    context "with sample from two months ago" do

      let(:sample_created_at) { 2.months.ago }

      it "should create new sample if it has same sample id but not in the same month, with monthly reset policy" do
        sample_identifier

        site = device.site
        site.sample_id_reset_policy = "monthly"
        site.save!

        TestResult.create_and_index test_id: TEST_ID_2, sample_identifier: sample_identifier, patient: patient, device: device

        refresh_index

        device_message_processor.process

        expect(Sample.count).to eq(2)
      end

      it "should not create new sample if it is a test update, even if it is not in from the same month" do
        sample_identifier

        site = device.site
        site.sample_id_reset_policy = "monthly"
        site.save!

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, patient: patient, device: device

        refresh_index

        device_message_processor.process

        expect(Sample.count).to eq(1)
      end

    end

    context 'with sample from two weeks ago' do

      let(:sample_created_at) { 2.weeks.ago }

      it "should create new sample if it has same sample id but not in the same month, with weekly reset policy" do
        sample_identifier

        site = device.site
        site.sample_id_reset_policy = "weekly"
        site.save!

        TestResult.create_and_index test_id: TEST_ID_2, sample_identifier: sample_identifier, patient: patient, device: device

        refresh_index

        device_message_processor.process

        expect(Sample.count).to eq(2)
      end

    end

    context "with sample from two years ago" do

      let(:sample_created_at) { 2.years.ago }

      it "should create new sample if it has same sample id" do
        sample_identifier

        refresh_index

        device_message_processor.process

        expect(Sample.count).to eq(2)
      end

      it "should not create new sample if it already belongs to the test" do
        TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, patient: patient, device: device

        refresh_index

        device_message_processor.process

        expect(Sample.count).to eq(1)
      end

    end

  end

  context "sample identification scope" do

    let(:core_fields) { {"type" => SAMPLE_TYPE} }
    let(:custom_fields) { {"hiv" => PATIENT_HIV} }

    it "shouldn't update sample from another institution" do
      sample = Sample.make!(
        core_fields: core_fields,
        custom_fields: custom_fields
      )

      sample_identifier = SampleIdentifier.make!(
        sample: sample,
        uuid: 'abc',
        entity_id: SAMPLE_ID
      )

      device_message_processor.process

      expect(Sample.count).to eq(2)

      sample = sample.reload

      expect(sample.core_fields).to eq(core_fields)
      expect(sample.custom_fields).to eq(custom_fields)
    end

    it "shouldn't update sample from another site" do
      sample = Sample.make!(
        core_fields: core_fields,
        custom_fields: custom_fields,
        institution: institution
      )

      sample_identifier = SampleIdentifier.make!(
        sample: sample,
        uuid: 'abc',
        entity_id: SAMPLE_ID,
        site: Site.make!(institution: institution)
      )

      device_message_processor.process

      expect(Sample.count).to eq(2)

      sample = sample.reload

      expect(sample.core_fields).to eq(core_fields)
      expect(sample.custom_fields).to eq(custom_fields)
    end

    it "should update sample from another site for manufacturer" do
      institution.update_attributes! kind: 'manufacturer'

      sample = Sample.make!(
        core_fields: core_fields,
        custom_fields: custom_fields,
        institution: institution
      )

      sample_identifier = SampleIdentifier.make!(
        sample: sample,
        uuid: 'abc',
        entity_id: SAMPLE_ID
      )

      device_message_processor.process

      expect(Sample.count).to eq(1)

      sample = sample.reload

      expect(sample.core_fields).to eq(core_fields.merge(SAMPLE_CORE_FIELDS))
      expect(sample.custom_fields).to eq(custom_fields.merge(SAMPLE_CUSTOM_FIELDS))
    end

  end

  it "should update tests with the same test_id" do
    test = TestResult.create_and_index(
      test_id: TEST_ID, device: device,
      custom_fields: {"concentration" => "10%", "foo" => "bar"},
      core_fields: {"assays" => [result("flu", "flu", "negative"), result("mtb1", "mtb1", "positive")]},
    )

    expect { device_message_processor.process }.to change(TestResult, :count).by(0)

    expect(Sample.count).to eq(1)

    tests = all_elasticsearch_tests
    expect(tests.size).to eq(1)

    expect(tests.first["_source"]["test"]["assays"]).to eq([{"name"=>"mtb", "condition"=>"mtb", "result"=>"positive"}])
    expect(tests.first["_source"]["sample"]["type"]).to eq(SAMPLE_TYPE)
    expect(tests.first["_source"]["test"]["custom_fields"]["concentration"]).to eq(TEST_CONCENTRATION)
    # tests.first["_source"]["test"]["custom_fields"]["foo"].should eq("bar")

    expect(TestResult.count).to eq(1)
    expect(TestResult.first.sample).to eq(Sample.last)
    # TestResult.first.custom_fields.should eq("raw_result" => TEST_RAW_RESULT)
    expect(TestResult.first.core_fields).to include("start_time" => TEST_START_TIME)
    expect(TestResult.first.sample_identifier.entity_id).to eq(SAMPLE_ID)
  end

  it "should not update test with same test_id if device has moved from original test site" do
    test = TestResult.create_and_index(
      test_id: TEST_ID, device: device, site: site,
      custom_fields: {"concentration" => "10%", "foo" => "bar"},
      core_fields: {"assays" => [result("flu", "flu", "negative"), result("mtb1", "mtb1", "positive")]},
    )

    new_device_site = Site.make! institution: institution
    device.site = new_device_site
    device.save!

    expect { device_message_processor.process }.to change(TestResult, :count).by(1)

    expect(TestResult.last.site).to eq(new_device_site)
  end

  it "should not update test with same test_id if the original site has moved (ie soft deleted)" do
    test = TestResult.create_and_index(
      test_id: TEST_ID, device: device, site: site,
      custom_fields: {"concentration" => "10%", "foo" => "bar"},
      core_fields: {"assays" => [result("flu", "flu", "negative"), result("mtb1", "mtb1", "positive")]},
    )

    new_device_site = Site.make! institution: institution
    device.site = new_device_site
    device.save!

    site.destroy!

    expect { device_message_processor.process }.to change(TestResult, :count).by(1)

    expect(TestResult.last.site).to eq(new_device_site)
  end

  it "should take tests with the same test_id but different year as differents" do
    test = TestResult.create_and_index(
      created_at: 2.years.ago,
      test_id: TEST_ID, device: device,
      custom_fields: {"concentration" => "10%", "foo" => "bar"},
      core_fields: {"assays" => [result("flu", "flu", "negative"), result("mtb1", "mtb1", "positive")]},
    )

    device_message_processor.process

    expect(TestResult.count).to eq(2)
  end

  context "test_result_parsed_data" do
    it "should store the parsed datum" do
      device_message_processor.process

      expect(TestResult.count).to eq(1)
      test = TestResult.first
      expect(test.test_result_parsed_data.count).to eq(1)
      expect(test.test_result_parsed_data.first).to eq(test.test_result_parsed_datum)
      expect(test.test_result_parsed_datum.data).to eq(parsed_message(TEST_ID))
    end

    it "should store all parsed data" do
      device_message_processor.process
      DeviceMessageProcessor.new(device_message).process

      expect(TestResult.count).to eq(1)
      test = TestResult.first
      expect(test.test_result_parsed_data.count).to eq(2)
      expect(test.test_result_parsed_data.last).to eq(test.test_result_parsed_datum)
      expect(test.test_result_parsed_datum.data).to eq(parsed_message(TEST_ID))
    end
  end

  context 'sample, patient and encounter entities' do
    context 'without sample id' do
      before :each do
        message = parsed_message(TEST_ID)
        message["sample"]["core"].delete("id")
        clear message, "patient", "encounter"
        allow(device_message).to receive("parsed_messages").and_return([message])
      end

      it 'should store sample data in test sample (without id) if test does not have a sample' do
        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)

        test = TestResult.first
        sample = test.sample
        expect(sample.sample_identifiers.map(&:entity_id)).to eq([nil])

        expect(sample.plain_sensitive_data).to eq(SAMPLE_PII_FIELDS)
        expect(sample.custom_fields).to eq(SAMPLE_CUSTOM_FIELDS)
        expect(sample.core_fields).to eq(SAMPLE_CORE_FIELDS.except("id"))
      end

      it 'should merge sample if test has a sample' do
        register_cdx_fields sample: { fields: { existing_field: {} } }

        sample = Sample.make!(
          institution: device_message.institution,
          core_fields: {"existing_field" => "a value"},
        )

        sample_identifier = SampleIdentifier.make!(
          sample: sample,
          uuid: 'abc',
          entity_id: SAMPLE_ID
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)

        sample = Sample.first

        expect(sample.plain_sensitive_data).to eq(SAMPLE_PII_FIELDS)
        expect(sample.custom_fields).to eq(SAMPLE_CUSTOM_FIELDS)

        # TODO: Should sample core fields include entity_ids?
        expect(sample.core_fields).to eq(SAMPLE_CORE_FIELDS.merge("existing_field" => "a value").except("id"))
      end
    end

    context 'with sample id' do
      before :each do
        message = parsed_message(TEST_ID)
        clear message, "patient", "encounter"
        allow(device_message).to receive("parsed_messages").and_return([message])
      end

      it 'should extract existing data in sample and create the sample entity with id' do
        register_cdx_fields sample: { fields: {
          existing_indexed_field: {},
          existing_pii_field: { pii: true }
        } }

        patient = Patient.make!(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID},
        )

        sample = Sample.make!(
          patient: patient,
          institution: device_message.institution,
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        sample_identifier = SampleIdentifier.make!(
          sample: sample
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, patient: patient, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)
        test = TestResult.first
        sample = test.sample

        expect(test.patient).to eq(patient)
        expect(sample.patient).to eq(patient)

        expect(sample.plain_sensitive_data).to eq(SAMPLE_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        expect(sample.custom_fields).to eq(SAMPLE_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        expect(sample.core_fields).to eq(SAMPLE_CORE_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should extract existing data in patient and create the patient entity with id' do
        register_cdx_fields patient: { fields: {
          existing_indexed_field: {},
          existing_pii_field: { pii: true }
        } }

        patient = Patient.make!(
          institution: device_message.institution,
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        sample = Sample.make! patient: patient, institution: device_message.institution

        sample_identifier = SampleIdentifier.make!(
          sample: sample
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, patient: patient, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Patient.count).to eq(1)
        test = TestResult.first
        patient = test.patient

        expect(patient.plain_sensitive_data).to eq("existing_pii_field" => "existing_pii_field_value")
        expect(patient.custom_fields).to eq("existing_custom_field" => "existing_custom_field_value")
        expect(patient.core_fields).to eq("existing_indexed_field" => "existing_indexed_field_value")
      end

      it 'should merge sample with existing sample if sample id matches' do
        register_cdx_fields sample: { fields: {
          existing_field: {}
        } }

        patient = Patient.make! institution: device_message.institution

        sample = Sample.make!(
          institution: device_message.institution, patient: patient,
          core_fields: {"existing_field" => "a value"},
        )

        sample_identifier = SampleIdentifier.make!(
          sample: sample,
          uuid: 'abc',
          entity_id: SAMPLE_ID
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, patient: patient, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)

        sample = TestResult.first.sample

        expect(sample.plain_sensitive_data).to eq(SAMPLE_PII_FIELDS)
        expect(sample.custom_fields).to eq(SAMPLE_CUSTOM_FIELDS)
        expect(sample.core_fields).to eq(SAMPLE_CORE_FIELDS.merge("existing_field" => "a value"))
      end

      it 'should create a new sample if the existing sample has a different sample id' do
        sample = Sample.make!(
          institution: device_message.institution
        )

        sample_identifier = SampleIdentifier.make!(
          sample: sample,
          uuid: 'abc',
          entity_id: "def9772"
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(2)

        sample = TestResult.first.sample
        assert_sample_data sample
      end

      it 'should not destroy existing sample if it has other references' do
        sample = Sample.make!(
          institution: device_message.institution
        )

        sample_identifier = SampleIdentifier.make!(
          sample: sample,
          uuid: 'abc',
          entity_id: "def9772"
        )

        test_1 = TestResult.create_and_index test_id: TEST_ID_2, sample_identifier: sample_identifier, device: device

        device_message_processor.process

        test_2 = TestResult.find_by(test_id: TEST_ID)

        expect(test_1.reload.sample.sample_identifiers.map(&:entity_id)).to eq(['def9772'])
        expect(test_2.reload.sample.sample_identifiers.map(&:entity_id)).to eq([SAMPLE_ID])
      end

      it "should assign existing sample's patient to the test" do
        patient = Patient.make!(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID},
        )

        sample = Sample.make!(
          institution: device_message.institution, patient: patient,
        )

        sample_identifier = SampleIdentifier.make!(
          sample: sample,
          uuid: 'abc',
          entity_id: SAMPLE_ID,
          site: site
        )

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)
        expect(Patient.count).to eq(1)

        test = TestResult.first
        expect(test.patient).to eq(test.sample.patient)
      end
    end

    context 'without patient id' do
      before :each do
        message = parsed_message(TEST_ID)
        message["patient"]["pii"].delete("id")
        clear message, "sample", "encounter"
        allow(device_message).to receive("parsed_messages").and_return([message])
      end

      it 'should merge patient into test patient if test has patient but not sample' do
        register_cdx_fields patient: { fields: {
          existing_indexed_field: {},
        } }

        patient = Patient.make!(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID},
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: nil, device: device, patient: patient

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(1)

        patient = TestResult.first.patient

        expect(patient.plain_sensitive_data).to eq(PATIENT_PII_FIELDS)
        expect(patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS)
        expect(patient.core_fields).to eq(PATIENT_CORE_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should merge patient into sample patient if sample has patient' do
        register_cdx_fields patient: { fields: {
          existing_indexed_field: {},
        } }

        patient = Patient.make!(
          plain_sensitive_data: {"id" => PATIENT_ID},
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          institution: device_message.institution
        )

        sample = Sample.make!(
          institution: device_message.institution, patient: patient,
        )

        sample_identifier = SampleIdentifier.make!(
          sample: sample,
          entity_id: SAMPLE_ID
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, patient: patient, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)
        expect(Patient.count).to eq(1)

        patient = TestResult.first.sample.patient

        expect(patient.plain_sensitive_data).to eq(PATIENT_PII_FIELDS)
        expect(patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS)
        expect(patient.core_fields).to eq(PATIENT_CORE_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should store patient data in patient without id if test does not have a sample or patient' do
        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(1)

        test = TestResult.first

        expect(test.patient.entity_id).to be_nil
        expect(test.patient.plain_sensitive_data).to eq("dob" => PATIENT_DOB)
        expect(test.patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS)
        expect(test.patient.core_fields).to eq(PATIENT_CORE_FIELDS)
      end

      it 'should store patient data in patient if sample is present but doest not have a patient' do
        sample = Sample.make!(
          institution: device_message.institution,
        )

        sample_identifier = SampleIdentifier.make!(
          sample: sample,
          entity_id: SAMPLE_ID
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)
        expect(Patient.count).to eq(1)

        patient = TestResult.first.sample.patient

        expect(patient.plain_sensitive_data).to eq("dob" => PATIENT_DOB)
        expect(patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS)
        expect(patient.core_fields).to eq(PATIENT_CORE_FIELDS)
      end
    end

    context 'with patient id' do
      before :each do
        message = parsed_message(TEST_ID)
        clear message, "sample", "encounter"
        allow(device_message).to receive("parsed_messages").and_return([message])

        register_cdx_fields patient: { fields: {
          existing_indexed_field: {},
          existing_pii_field: { pii: true },
        } }
      end

      it 'should extract existing data in test and create the patient entity' do
        patient = Patient.make!(
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
          institution: device_message.institution
        )

        TestResult.create_and_index(
          test_id: TEST_ID, sample_identifier: nil, patient: patient, device: device,
        )

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(1)

        patient = TestResult.first.patient

        expect(patient.plain_sensitive_data).to eq(PATIENT_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        expect(patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        expect(patient.core_fields).to eq(PATIENT_CORE_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should extract existing data in patient and create the patient entity' do
        patient = Patient.make!(
          institution: device_message.institution,
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
        )

        sample = Sample.make!(
          institution: device_message.institution, patient: patient,
          plain_sensitive_data: SAMPLE_PII_FIELDS,
        )

        sample_identifier = SampleIdentifier.make!(
          sample: sample
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: sample_identifier, patient: patient, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(0)     # Sample ends up being empty and is collected by the blender
        expect(Patient.count).to eq(1)

        patient = TestResult.first.patient

        expect(patient.plain_sensitive_data).to eq(PATIENT_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        expect(patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        expect(patient.core_fields).to eq(PATIENT_CORE_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should merge patient with existing patient if patient id matches' do
        patient = Patient.make!(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID, "existing_pii_field" => "existing_pii_field_value"},
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: nil, device: device, patient: patient

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(1)

        patient = TestResult.first.patient

        expect(patient.plain_sensitive_data).to eq(PATIENT_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        expect(patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        expect(patient.core_fields).to eq(PATIENT_CORE_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it "should merge patient with existing patient if patient id matches, even if it's a different year" do
        patient = Patient.make!(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID, "existing_pii_field" => "existing_pii_field_value"},
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          created_at: 2.years.ago,
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: nil, device: device, patient: patient

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(1)

        patient = TestResult.first.patient

        expect(patient.plain_sensitive_data).to eq(PATIENT_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        expect(patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        expect(patient.core_fields).to eq(PATIENT_CORE_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it "should merge patient with existing patient if patient id matches, even if it's a different site" do
        patient = Patient.make!(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID, "existing_pii_field" => "existing_pii_field_value"},
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          created_at: 2.years.ago,
        )
        other_device = Device.make!(institution: institution, site: Site.make!(institution: institution))
        TestResult.create_and_index test_id: TEST_ID_2, sample_identifier: nil, device: other_device, patient: patient

        device_message_processor.process

        expect(TestResult.count).to eq(2)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(1)

        patient = TestResult.first.patient

        expect(patient.plain_sensitive_data).to eq(PATIENT_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        expect(patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        expect(patient.core_fields).to eq(PATIENT_CORE_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should create a new patient if the existing patient has a differente patient id' do
        patient = Patient.make!(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => "9000"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: nil, device: device, patient: patient

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(2)

        patient = TestResult.first.patient
        assert_patient_data(patient)
      end

      it 'should not destroy existing patient if it has other references' do
        patient = Patient.make!(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => "9000"},
        )

        test_1 = TestResult.create_and_index test_id: TEST_ID_2, sample_identifier: nil, device: device, patient: patient

        device_message_processor.process

        test_2 = TestResult.find_by(test_id: TEST_ID)

        expect(test_1.reload.patient.entity_id).to eq('9000')
        expect(test_2.patient.entity_id).to eq(PATIENT_ID)
      end

      it 'should create patient and store reference in test and sample' do
        TestResult.create_and_index test_id: TEST_ID, device: device,\
          sample_identifier: SampleIdentifier.make!(entity_id: SAMPLE_ID, sample: Sample.make!(institution: device_message_processor.institution))

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)
        expect(Patient.count).to eq(1)

        test = TestResult.first
        patient = Patient.first

        expect(test.patient).to eq(patient)
        expect(test.sample.patient).to eq(patient)
      end
    end

    context 'without encounter id' do
      before :each do
        message = parsed_message(TEST_ID)
        message["encounter"]["core"].delete("id")
        clear message, "patient", "sample"
        allow(device_message).to receive("parsed_messages").and_return([message])
      end

      it 'should store encounter data in entity without id if test does not have an encounter' do
        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Encounter.count).to eq(1)

        encounter = TestResult.first.encounter
        expect(encounter.entity_id).to be_nil
        expect(encounter.custom_fields).to eq(ENCOUNTER_CUSTOM_FIELDS)
      end

      it 'should merge encounter if test has an encounter' do
        encounter = Encounter.make!(
          uuid: 'ghi', institution: device_message.institution,
          custom_fields: {"existing_field" => "a value"},
          plain_sensitive_data: ENCOUNTER_PII_FIELDS,
        )

        TestResult.create_and_index test_id: TEST_ID, encounter: encounter, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Encounter.count).to eq(1)

        encounter = Encounter.first

        expect(encounter.plain_sensitive_data).to eq(ENCOUNTER_PII_FIELDS)
        expect(encounter.custom_fields).to eq(ENCOUNTER_CUSTOM_FIELDS.merge("existing_field" => "a value"))
      end
    end

    context 'with encounter id' do
      before :each do
        message = parsed_message(TEST_ID)
        clear message, "patient", "sample"
        allow(device_message).to receive("parsed_messages").and_return([message])
      end

      it 'should extract existing data in encounter and create the encounter entity' do
        register_cdx_fields encounter: { fields: {
          existing_indexed_field: {},
          existing_pii_field: { pii: true },
        } }

        encounter = Encounter.make!(
          uuid: 'ghi', institution: device_message.institution,
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample_identifier: nil, device: device, encounter: encounter

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(0)
        expect(Encounter.count).to eq(1)

        encounter = TestResult.first.encounter

        expect(encounter.plain_sensitive_data).to eq(ENCOUNTER_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        expect(encounter.custom_fields).to eq(ENCOUNTER_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
      end

      it 'should merge encounter if id matches within institution on different sites' do
        register_cdx_fields encounter: { fields: {
          existing_indexed_field: {},
          existing_pii_field: { pii: true },
        } }

        encounter = Encounter.make!(
          uuid: 'ghi', institution: device_message.institution,
          core_fields: {"id" => ENCOUNTER_ID, "existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        other_device = Device.make!(institution: institution, site: Site.make!(institution: institution))
        TestResult.create_and_index test_id: TEST_ID_2, sample_identifier: nil, device: other_device, encounter: encounter

        device_message_processor.process

        expect(TestResult.count).to eq(2)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(0)
        expect(Encounter.count).to eq(1)

        encounter = TestResult.first.encounter

        expect(encounter.plain_sensitive_data).to eq(ENCOUNTER_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        expect(encounter.custom_fields).to eq(ENCOUNTER_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        expect(encounter.core_fields).to include(ENCOUNTER_CORE_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it "should update encounter if encounter_id changes" do
        old_encounter = Encounter.make!(
          uuid: 'ghi', institution: device_message.institution,
          core_fields: {"id" => "ANOTHER ID"},
        )

        test = TestResult.create_and_index test_id: TEST_ID, device: device, encounter: old_encounter

        device_message_processor.process

        expect(Encounter.count).to eq(2)

        encounter = Encounter.first
        encounter2 = TestResult.first.encounter
        expect(encounter).not_to eq(encounter2)
      end
    end

    context 'with encounter id and multiple tests' do
      it "sets encounter's times to test result times, with one" do
        start_time = 2.years.ago.at_beginning_of_day
        end_time = 2.years.from_now.at_beginning_of_day
        message = parsed_message(TEST_ID, "test" => {"core" => {"start_time" => start_time, "end_time" => end_time}})
        clear message, "patient", "sample"
        allow(device_message).to receive(:parsed_messages).and_return([message])

        device_message_processor.process

        encounter = Encounter.first
        expect(Time.parse(encounter.core_fields["start_time"]).at_beginning_of_day).to eq(start_time)
        expect(Time.parse(encounter.core_fields["end_time"]).at_beginning_of_day).to eq(end_time)
      end

      it "sets encounter's times to test result times, with two" do
        start_time_1 = 2.years.ago.at_beginning_of_day
        end_time_1 = 2.years.from_now.at_beginning_of_day

        start_time_2 = 3.years.ago.at_beginning_of_day
        end_time_2 = 3.years.from_now.at_beginning_of_day

        messages = [
          parsed_message(TEST_ID, "test" => {"core" => {"start_time" => start_time_1, "end_time" => end_time_1}}, "encounter" => {"core" => {"uuid" => "1234"}}),
          parsed_message(TEST_ID_2, "test" => {"core" => {"start_time" => start_time_2, "end_time" => end_time_2}}, "encounter" => {"core" => {"uuid" => "1234"}}),
        ]
        messages.each do |message|
          clear message, "patient", "sample"
        end
        allow(device_message).to receive(:parsed_messages).and_return(messages)

        device_message_processor.process

        encounter = Encounter.first
        expect(Time.parse(encounter.core_fields["start_time"]).at_beginning_of_day).to eq(start_time_2)
        expect(Time.parse(encounter.core_fields["end_time"]).at_beginning_of_day).to eq(end_time_2)
      end
    end
  end
    
   context 'check invalid time' do
      let(:device_message_processor) {DeviceMessageProcessor.new(device_message)}
     
      it "the start time is greater than today and generates and alert" do
        alert = Alert.make!(:category_type =>"anomalies", :anomalie_type => "invalid_test_date")
        alert.query = {"test.error_code"=>"155"}
        alert.institution_id = institution.id
        alert.sample_id=""
        alert.user = institution.user
        alert.save!

        @check_invalid_test=TRUE
        device_message_processor.process
        expect(AlertHistory.count).to equal (1)
      end
    end
  
end
