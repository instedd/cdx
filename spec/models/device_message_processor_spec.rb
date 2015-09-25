require "spec_helper"

describe DeviceMessageProcessor, elasticsearch: true do
  TEST_ID   = "4"
  TEST_ID_2 = "5"
  TEST_ID_3 = "6"

  TEST_RAW_RESULT         = "positivo 15%"
  TEST_CONCENTRATION      = "15%"
  TEST_START_TIME         = "2000/1/1 10:00:00"

  SAMPLE_ID               = "4002"
  SAMPLE_DATAGRAM         = "010100011100"
  SAMPLE_CULTURE_DAYS     = "10"
  SAMPLE_TYPE             = "sputum"
  SAMPLE_COLLECTION_DATE  = "2000/1/1 9:00:00"
  SAMPLE_PII_FIELDS       = {}.freeze
  SAMPLE_CORE_FIELDS      = {"id" => SAMPLE_ID, "type" => SAMPLE_TYPE, "collection_date" => SAMPLE_COLLECTION_DATE}.freeze
  SAMPLE_CUSTOM_FIELDS    = {"datagram" => SAMPLE_DATAGRAM, "culture_days" => SAMPLE_CULTURE_DAYS}.freeze

  PATIENT_ID              = "8000"
  PATIENT_GENDER          = "male"
  PATIENT_DOB             = "2000/1/1"
  PATIENT_SHIRT_COLOR     = "blue"
  PATIENT_HIV             = "positive"
  PATIENT_PII_FIELDS      = {"id" => PATIENT_ID, "dob" => PATIENT_DOB}.freeze
  PATIENT_CORE_FIELDS     = {"gender" => PATIENT_GENDER}.freeze
  PATIENT_CUSTOM_FIELDS   = {"shirt_color" => PATIENT_SHIRT_COLOR, "hiv" => PATIENT_HIV}.freeze

  ENCOUNTER_ID            = "1234"
  ENCOUNTER_CORE_FIELDS   = {"id" => ENCOUNTER_ID}.freeze
  ENCOUNTER_PII_FIELDS    = {}.freeze
  ENCOUNTER_CUSTOM_FIELDS = {"time" => "2001/1/1 10:00:00"}.freeze

  def parsed_message(test_id, params={})
    {
      "test" => {
        "core" => {
          "id" => test_id,
          "assay" => "mtb",
          "results" => [
            {
              "result" => "positive",
              "condition" => "mtb"
            }
          ]
        },
        "custom" => {
          "raw_result" => TEST_RAW_RESULT,
          "concentration" => TEST_CONCENTRATION
        },
        "pii" => {
          "start_time" => TEST_START_TIME
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

  def result(condition, result)
    {"result" => result, "condition" => condition}
  end

  def clear(message, *scopes)
    scopes.each do |scope|
      message[scope]["pii"] = {}
      message[scope]["custom"] = {}
      message[scope]["core"] = {}
    end
  end

  let(:device) {Device.make}

  let(:institution) {device.institution}

  let(:device_message) do
    device_message = DeviceMessage.new(device: device, plain_text_data: '{}')
    allow(device_message).to receive(:parsed_messages).and_return([parsed_message(TEST_ID)])
    device_message.save!
    device_message
  end

  let(:device_message_processor) {DeviceMessageProcessor.new(device_message)}

  def assert_encounter_data(encounter)
    expect(encounter.core_fields).to eq(ENCOUNTER_CORE_FIELDS)
    expect(encounter.plain_sensitive_data).to eq(ENCOUNTER_PII_FIELDS)
    expect(encounter.custom_fields).to eq(ENCOUNTER_CUSTOM_FIELDS)
  end

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

  def assert_test_data(test)
    expect(test.plain_sensitive_data).to eq("start_time" => TEST_START_TIME)
    expect(test.custom_fields).to eq("raw_result" => TEST_RAW_RESULT, "concentration" => TEST_CONCENTRATION)
  end

  it "should create a test result" do
    device_message_processor.process

    expect(TestResult.count).to eq(1)
    test = TestResult.first
    expect(test.test_id).to eq(TEST_ID)
    assert_test_data(test)
  end

  it "should create a sample" do
    device_message_processor.process

    expect(Sample.count).to eq(1)
    sample = Sample.first
    expect(sample.entity_id).to eq(SAMPLE_ID)
    assert_sample_data(sample)
  end

  it "should create an encounter" do
    device_message_processor.process

    expect(Encounter.count).to eq(1)
    encounter = Encounter.first
    expect(encounter.entity_id_hash).to eq(MessageEncryption.hash ENCOUNTER_ID)
    assert_encounter_data(encounter)
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
    expect(TestResult.pluck(:sample_id)).to eq([Sample.first.id] * 3)

    expect(all_elasticsearch_tests.map {|e| e['_source']['sample']['uuid']}).to eq([Sample.first.uuid] * 3)
  end

  it "should update sample data and existing test results on new test result" do
    patient = Patient.make(
      uuid: 'def', institution: device_message.institution,
      core_fields: PATIENT_CORE_FIELDS,
      plain_sensitive_data: {"id" => PATIENT_ID},
    )

    sample = Sample.make(
      uuid: 'abc', institution: device_message.institution, patient: patient,
      core_fields: {"type" => "blood", "id" => SAMPLE_ID},
    )

    TestResult.create_and_index test_id: TEST_ID_2, sample: sample, patient: patient, device: device
    TestResult.create_and_index test_id: TEST_ID_3, sample: sample, patient: patient, device: device

    refresh_index

    device_message_processor.process

    expect(Sample.count).to eq(1)
    expect(Patient.count).to eq(1)
    sample = Sample.first
    assert_sample_data(sample)
    assert_patient_data(sample.patient)

    tests = all_elasticsearch_tests
    expect(tests.map { |test| test["_source"]["sample"]["type"] }).to eq([SAMPLE_TYPE] * 3)
  end

  it "should create new sample if it has same sample id but not in the same year" do
    patient = Patient.make(
      uuid: 'def', institution: device_message.institution,
      core_fields: PATIENT_CORE_FIELDS,
      plain_sensitive_data: {"id" => PATIENT_ID},
    )

    sample = Sample.make(
      uuid: 'abc', institution: device_message.institution, patient: patient,
      core_fields: {"type" => "blood", "id" => SAMPLE_ID},
      created_at: 2.years.ago,
    )

    TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device

    refresh_index

    device_message_processor.process

    expect(Sample.count).to eq(2)
  end

  it "should update sample data and existing test results on test result update" do
    patient = Patient.make(
      uuid: 'def', institution: device_message.institution,
      core_fields: PATIENT_CORE_FIELDS,
      plain_sensitive_data: {"id" => PATIENT_ID},
    )
    sample = Sample.make(
      uuid: 'abc', institution: device_message.institution, patient: patient,
      core_fields: {"type" => "blood", "id" => SAMPLE_ID},
    )

    TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device
    TestResult.create_and_index test_id: TEST_ID_2, sample: sample, patient: patient, device: device

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
    patient = Patient.make(
      uuid: 'def', institution: device_message.institution,
      core_fields: PATIENT_CORE_FIELDS,
      plain_sensitive_data: {"id" => PATIENT_ID},
    )
    sample = Sample.make(
      uuid: 'abc', institution: device_message.institution, patient: patient,
      core_fields: SAMPLE_CORE_FIELDS,
    )

    TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device
    TestResult.create_and_index test_id: TEST_ID_2, sample: sample, patient: patient, device: device

    refresh_index

    expect(device_message_processor.client).to receive(:bulk).never
    device_message_processor.process

    expect(Sample.count).to eq(1)
    expect(Patient.count).to eq(1)
    sample = Sample.first
    assert_sample_data(sample)
    assert_patient_data(sample.patient)
  end

  it "shouldn't update sample from another institution" do
    core_fields = {"type" => SAMPLE_TYPE, "custom_fields" => {"hiv" => PATIENT_HIV}, "id" => SAMPLE_ID}

    sample = Sample.make(
      uuid: 'abc',
      core_fields: core_fields,
    )
    device_message_processor.process

    expect(Sample.count).to eq(2)

    sample = sample.reload

    expect(sample.core_fields).to eq(core_fields)
  end

  it "should update tests with the same test_id and different sample_id" do
    test = TestResult.create_and_index(
      test_id: TEST_ID, device: device,
      custom_fields: {"concentration" => "10%", "foo" => "bar"},
      core_fields: {"results" => [result("flu", "negative"), result("mtb1", "pos")]},
    )

    device_message_processor.process

    expect(Sample.count).to eq(1)

    tests = all_elasticsearch_tests
    expect(tests.size).to eq(1)

    expect(tests.first["_source"]["test"]["assay"]).to eq("mtb")
    expect(tests.first["_source"]["sample"]["type"]).to eq(SAMPLE_TYPE)
    expect(tests.first["_source"]["test"]["custom_fields"]["concentration"]).to eq(TEST_CONCENTRATION)
    # tests.first["_source"]["test"]["custom_fields"]["foo"].should eq("bar")

    expect(TestResult.count).to eq(1)
    expect(TestResult.first.sample_id).to eq(Sample.last.id)
    # TestResult.first.custom_fields.should eq("raw_result" => TEST_RAW_RESULT)
    expect(TestResult.first.plain_sensitive_data).to eq("start_time" => TEST_START_TIME)
  end

  it "should take tests with the same test_id but different year as differents" do
    test = TestResult.create_and_index(
      created_at: 2.years.ago,
      test_id: TEST_ID, device: device,
      custom_fields: {"concentration" => "10%", "foo" => "bar"},
      core_fields: {"results" => [result("flu", "negative"), result("mtb1", "pos")]},
    )

    device_message_processor.process

    expect(TestResult.count).to eq(2)
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
        expect(sample.entity_id).to be_nil

        expect(sample.plain_sensitive_data).to eq(SAMPLE_PII_FIELDS)
        expect(sample.custom_fields).to eq(SAMPLE_CUSTOM_FIELDS)
        expect(sample.core_fields).to eq(SAMPLE_CORE_FIELDS.except("id"))
      end

      it 'should merge sample if test has a sample' do
        sample = Sample.make(
          uuid: 'abc', institution: device_message.institution,
          core_fields: {"existing_field" => "a value", "id" => SAMPLE_ID},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)

        sample = Sample.first

        expect(sample.plain_sensitive_data).to eq(SAMPLE_PII_FIELDS)
        expect(sample.custom_fields).to eq(SAMPLE_CUSTOM_FIELDS)
        expect(sample.core_fields).to eq(SAMPLE_CORE_FIELDS.merge("existing_field" => "a value"))
      end
    end

    context 'with sample id' do
      before :each do
        message = parsed_message(TEST_ID)
        clear message, "patient", "encounter"
        allow(device_message).to receive("parsed_messages").and_return([message])
      end

      it 'should extract existing data in sample and create the sample entity with id' do
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID},
        )

        sample = Sample.make(
          patient: patient,
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device

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
        patient = Patient.make(
          institution: device_message.institution,
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        sample = Sample.make patient: patient

        TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device

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
        patient = Patient.make institution: device_message.institution

        sample = Sample.make(
          uuid: 'abc', institution: device_message.institution, patient: patient,
          core_fields: {"existing_field" => "a value", "id" => SAMPLE_ID},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)

        sample = TestResult.first.sample

        expect(sample.plain_sensitive_data).to eq(SAMPLE_PII_FIELDS)
        expect(sample.custom_fields).to eq(SAMPLE_CUSTOM_FIELDS)
        expect(sample.core_fields).to eq(SAMPLE_CORE_FIELDS.merge("existing_field" => "a value"))
      end

      it 'should create a new sample if the existing sample has a different sample id' do
        sample = Sample.make(
          uuid: 'abc', institution: device_message.institution,
          core_fields: {"id" => "def9772"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(2)

        sample = TestResult.first.sample
        assert_sample_data sample
      end

      it 'should not destroy existing sample if it has other references' do
        sample = Sample.make(
          uuid: 'abc', institution: device_message.institution,
          core_fields: {"id" => "def9772"},
        )

        test_1 = TestResult.create_and_index test_id: TEST_ID_2, sample: sample, device: device

        device_message_processor.process

        test_2 = TestResult.find_by(test_id: TEST_ID)

        expect(test_1.reload.sample.entity_id).to eq('def9772')
        expect(test_2.reload.sample.entity_id).to eq(SAMPLE_ID)
      end

      it "should assign existing sample's patient to the test" do
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"patient_id" => PATIENT_ID},
        )

        Sample.make(
          institution: device_message.institution, patient: patient,
          core_fields: {"id" => SAMPLE_ID},
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
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID},
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: nil, device: device, patient: patient

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
        patient = Patient.make(
          plain_sensitive_data: {"id" => PATIENT_ID},
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          institution: device_message.institution
        )

        sample = Sample.make(
          institution: device_message.institution, patient: patient,
          core_fields: {"id" => SAMPLE_ID},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device

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
        sample = Sample.make(
          institution: device_message.institution,
          core_fields: {"id" => SAMPLE_ID},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, device: device

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
      end

      it 'should extract existing data in test and create the patient entity' do
        patient = Patient.make(
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        TestResult.create_and_index(
          test_id: TEST_ID, sample: nil, patient: patient, device: device,
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
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
        )

        sample = Sample.make(
          institution: device_message.institution, patient: patient,
          plain_sensitive_data: SAMPLE_PII_FIELDS,
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)
        expect(Patient.count).to eq(1)

        patient = TestResult.first.sample.patient

        expect(patient.plain_sensitive_data).to eq(PATIENT_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        expect(patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        expect(patient.core_fields).to eq(PATIENT_CORE_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should merge patient with existing patient if patient id matches' do
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID, "existing_pii_field" => "existing_pii_field_value"},
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: nil, device: device, patient: patient

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
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID, "existing_pii_field" => "existing_pii_field_value"},
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          created_at: 2.years.ago,
        )

        TestResult.create_and_index test_id: TEST_ID, sample: nil, device: device, patient: patient

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(1)

        patient = TestResult.first.patient

        expect(patient.plain_sensitive_data).to eq(PATIENT_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        expect(patient.custom_fields).to eq(PATIENT_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        expect(patient.core_fields).to eq(PATIENT_CORE_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should create a new patient if the existing patient has a differente patient id' do
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => "9000"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: nil, device: device, patient: patient

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(2)

        patient = TestResult.first.patient
        assert_patient_data(patient)
      end

      it 'should not destroy existing patient if it has other references' do
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => "9000"},
        )

        test_1 = TestResult.create_and_index test_id: TEST_ID_2, sample: nil, device: device, patient: patient

        device_message_processor.process

        test_2 = TestResult.find_by(test_id: TEST_ID)

        expect(test_1.reload.patient.entity_id).to eq('9000')
        expect(test_2.patient.entity_id).to eq(PATIENT_ID)
      end

      it 'should create patient and store reference in test and sample' do
        TestResult.create_and_index test_id: TEST_ID, device: device

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(1)
        expect(Patient.count).to eq(1)

        test = TestResult.first

        expect(test.patient).to eq(test.sample.patient)
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
        encounter = Encounter.make(
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
        encounter = Encounter.make(
          uuid: 'ghi', institution: device_message.institution,
          core_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: nil, device: device, encounter: encounter

        device_message_processor.process

        expect(TestResult.count).to eq(1)
        expect(Sample.count).to eq(0)
        expect(Patient.count).to eq(0)
        expect(Encounter.count).to eq(1)

        encounter = TestResult.first.encounter

        expect(encounter.plain_sensitive_data).to eq(ENCOUNTER_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        expect(encounter.custom_fields).to eq(ENCOUNTER_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
      end

      it "should update encounter if encounter_id changes" do
        old_encounter = Encounter.make(
          uuid: 'ghi', institution: device_message.institution,
          plain_sensitive_data: {"id" => "ANOTHER ID"},
        )

        test = TestResult.create_and_index test_id: TEST_ID, device: device, encounter: old_encounter

        device_message_processor.process

        expect(Encounter.count).to eq(2)

        encounter = Encounter.first
        encounter2 = TestResult.first.encounter
        expect(encounter).not_to eq(encounter2)
      end
    end
  end
end
