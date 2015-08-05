require "spec_helper"

describe DeviceMessageProcessor, elasticsearch: true do
  TEST_ID   = "4"
  TEST_ID_2 = "5"
  TEST_ID_3 = "6"

  TEST_RAW_RESULT         = "positivo 15%"
  TEST_CONCENTRATION      = "15%"
  TEST_START_TIME         = "2000/1/1 10:00:00"

  SAMPLE_ID               = "4002"
  SAMPLE_UID              = "abc4002"
  SAMPLE_DATAGRAM         = "010100011100"
  SAMPLE_CULTURE_DAYS     = "10"
  SAMPLE_TYPE             = "sputum"
  SAMPLE_COLLECTION_DATE  = "2000/1/1 9:00:00"
  SAMPLE_PII_FIELDS       = {"id" => SAMPLE_ID, "uid" => SAMPLE_UID}.freeze
  SAMPLE_INDEXED_FIELDS   = {"type" => SAMPLE_TYPE, "collection_date" => SAMPLE_COLLECTION_DATE}.freeze
  SAMPLE_CUSTOM_FIELDS    = {"datagram" => SAMPLE_DATAGRAM, "culture_days" => SAMPLE_CULTURE_DAYS}.freeze

  PATIENT_ID              = "8000"
  PATIENT_GENDER          = "male"
  PATIENT_DOB             = "2000/1/1"
  PATIENT_SHIRT_COLOR     = "blue"
  PATIENT_HIV             = "positive"
  PATIENT_PII_FIELDS      = {"id" => PATIENT_ID, "dob" => PATIENT_DOB}.freeze
  PATIENT_INDEXED_FIELDS  = {"gender" => PATIENT_GENDER}.freeze
  PATIENT_CUSTOM_FIELDS   = {"shirt_color" => PATIENT_SHIRT_COLOR, "hiv" => PATIENT_HIV}.freeze

  ENCOUNTER_ID            = "1234"
  ENCOUNTER_PII_FIELDS    = {"id" => ENCOUNTER_ID}.freeze
  ENCOUNTER_CUSTOM_FIELDS = {"time" => "2001/1/1 10:00:00"}

  def parsed_message(test_id, params={})
    {
      "test" => {
        "indexed" => {
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
        "indexed" => SAMPLE_INDEXED_FIELDS.dup,
        "custom" => SAMPLE_CUSTOM_FIELDS.dup,
        "pii" => SAMPLE_PII_FIELDS.dup
      },
      "patient" => {
        "indexed" => PATIENT_INDEXED_FIELDS.dup,
        "pii" => PATIENT_PII_FIELDS.dup,
        "custom" => PATIENT_CUSTOM_FIELDS.dup,
      },
      "encounter" => {
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
      message[scope]["indexed"] = {}
    end
  end

  let(:device) {Device.make}

  let(:institution) {device.institution}

  let(:device_message) do
    device_message = DeviceMessage.new(device: device, plain_text_data: '{}')
    device_message.stub(:parsed_messages).and_return([parsed_message(TEST_ID)])
    device_message.save!
    device_message
  end

  let(:device_message_processor) {DeviceMessageProcessor.new(device_message)}

  def assert_encounter_data(encounter)
    encounter.plain_sensitive_data.should eq(ENCOUNTER_PII_FIELDS)
    encounter.custom_fields.should eq(ENCOUNTER_CUSTOM_FIELDS)
  end

  def assert_sample_data(sample)
    sample.plain_sensitive_data.should eq(SAMPLE_PII_FIELDS)
    sample.custom_fields.should eq(SAMPLE_CUSTOM_FIELDS)
    sample.indexed_fields.should eq(SAMPLE_INDEXED_FIELDS)
  end

  def assert_patient_data(patient)
    patient.plain_sensitive_data.should eq(PATIENT_PII_FIELDS)
    patient.custom_fields.should eq(PATIENT_CUSTOM_FIELDS)
    patient.indexed_fields.should eq(PATIENT_INDEXED_FIELDS)
  end

  def assert_test_data(test)
    test.plain_sensitive_data.should eq("start_time" => TEST_START_TIME)
    test.custom_fields.should eq("raw_result" => TEST_RAW_RESULT, "concentration" => TEST_CONCENTRATION)
  end

  it "should create a test result" do
    device_message_processor.process

    TestResult.count.should eq(1)
    test = TestResult.first
    test.test_id.should eq(TEST_ID)
    assert_test_data(test)
  end

  it "should create a sample" do
    device_message_processor.process

    Sample.count.should eq(1)
    sample = Sample.first
    sample.sample_uid_hash.should eq(MessageEncryption.hash SAMPLE_UID)
    assert_sample_data(sample)
  end

  it "should create an encounter" do
    device_message_processor.process

    Encounter.count.should eq(1)
    encounter = Encounter.first
    encounter.encounter_id.should eq(ENCOUNTER_ID)
    assert_encounter_data(encounter)
  end

  it "should create a patient" do
    device_message_processor.process

    Patient.count.should eq(1)
    patient = Patient.first
    patient.patient_id_hash.should eq(MessageEncryption.hash PATIENT_ID)
    assert_patient_data(patient)
  end

  it "should not update existing tests on new sample" do
    device_message_processor.client.should_receive(:bulk).never
    device_message_processor.process
  end

  it "should create multiple test results with single sample" do
    device_message.stub(:parsed_messages).and_return([parsed_message(TEST_ID), parsed_message(TEST_ID_2), parsed_message(TEST_ID_3)])
    device_message_processor.process

    Sample.count.should eq(1)

    TestResult.count.should eq(3)
    TestResult.pluck(:test_id).should =~ [TEST_ID, TEST_ID_2, TEST_ID_3]
    TestResult.pluck(:sample_id).should eq([Sample.first.id] * 3)

    all_elasticsearch_tests.map {|e| e['_source']['sample']['uuid']}.should eq([Sample.first.uuid] * 3)
  end

  it "should update sample data and existing test results on new test result" do
    patient = Patient.make(
      uuid: 'def', institution: device_message.institution,
      indexed_fields: PATIENT_INDEXED_FIELDS,
      plain_sensitive_data: {"id" => PATIENT_ID},
    )

    sample = Sample.make(
      uuid: 'abc', institution: device_message.institution, patient: patient,
      indexed_fields: {"type" => "blood"},
      plain_sensitive_data: {"uid" => SAMPLE_UID},
    )

    TestResult.create_and_index test_id: TEST_ID_2, sample: sample, patient: patient, device: device
    TestResult.create_and_index test_id: TEST_ID_3, sample: sample, patient: patient, device: device

    refresh_index

    device_message_processor.process

    Sample.count.should eq(1)
    Patient.count.should eq(1)
    sample = Sample.first
    assert_sample_data(sample)
    assert_patient_data(sample.patient)

    tests = all_elasticsearch_tests
    tests.map { |test| test["_source"]["sample"]["type"] }.should eq([SAMPLE_TYPE] * 3)
  end

  it "should update sample data and existing test results on test result update" do
    patient = Patient.make(
      uuid: 'def', institution: device_message.institution,
      indexed_fields: PATIENT_INDEXED_FIELDS,
      plain_sensitive_data: {"id" => PATIENT_ID},
    )
    sample = Sample.make(
      uuid: 'abc', institution: device_message.institution, patient: patient,
      indexed_fields: {"type" => "blood"},
      plain_sensitive_data: {"uid" => SAMPLE_UID},
    )

    TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device
    TestResult.create_and_index test_id: TEST_ID_2, sample: sample, patient: patient, device: device

    refresh_index

    device_message_processor.process

    Sample.count.should eq(1)
    Patient.count.should eq(1)
    sample = Sample.first
    assert_sample_data(sample)
    assert_patient_data(sample.patient)

    tests = all_elasticsearch_tests
    tests.map { |test| test["_source"]["sample"]["type"] }.should eq([SAMPLE_TYPE] * 2)
  end

  it "should not update existing tests if sample data indexed fields did not change" do
    patient = Patient.make(
      uuid: 'def', institution: device_message.institution,
      indexed_fields: PATIENT_INDEXED_FIELDS,
      plain_sensitive_data: {"id" => PATIENT_ID},
    )
    sample = Sample.make(
      uuid: 'abc', institution: device_message.institution, patient: patient,
      indexed_fields: SAMPLE_INDEXED_FIELDS,
      plain_sensitive_data: {"uid" => SAMPLE_UID},
    )

    TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device
    TestResult.create_and_index test_id: TEST_ID_2, sample: sample, patient: patient, device: device

    refresh_index

    device_message_processor.client.should_receive(:bulk).never
    device_message_processor.process

    Sample.count.should eq(1)
    Patient.count.should eq(1)
    sample = Sample.first
    assert_sample_data(sample)
    assert_patient_data(sample.patient)
  end

  it "shouldn't update sample from another institution" do
    indexed_fields = {"type" => SAMPLE_TYPE, "custom_fields" => {"hiv" => PATIENT_HIV}}

    sample = Sample.make(
      uuid: 'abc',
      indexed_fields: indexed_fields,
      plain_sensitive_data: {"uid" => SAMPLE_UID},
    )
    device_message_processor.process

    Sample.count.should eq(2)

    sample = sample.reload

    sample.plain_sensitive_data.should eq("uid" => SAMPLE_UID)
    sample.indexed_fields.should eq(indexed_fields)
  end

  it "should update tests with the same test_id and different sample_uid" do
    test = TestResult.create_and_index(
      test_id: TEST_ID, device: device,
      custom_fields: {"concentration" => "10%", "foo" => "bar"},
      indexed_fields: {"results" => [result("flu", "negative"), result("mtb1", "pos")]},
    )

    device_message_processor.process

    Sample.count.should eq(1)

    tests = all_elasticsearch_tests
    tests.size.should eq(1)

    tests.first["_source"]["test"]["assay"].should eq("mtb")
    tests.first["_source"]["sample"]["type"].should eq(SAMPLE_TYPE)
    tests.first["_source"]["test"]["custom_fields"]["concentration"].should eq(TEST_CONCENTRATION)
    # tests.first["_source"]["test"]["custom_fields"]["foo"].should eq("bar")

    TestResult.count.should eq(1)
    TestResult.first.sample_id.should eq(Sample.last.id)
    # TestResult.first.custom_fields.should eq("raw_result" => TEST_RAW_RESULT)
    TestResult.first.plain_sensitive_data.should eq("start_time" => TEST_START_TIME)
  end

  context 'sample, patient and encounter entities' do
    context 'without sample uid' do
      before :each do
        message = parsed_message(TEST_ID)
        message["sample"]["pii"].delete("uid")
        clear message, "patient", "encounter"
        device_message.stub("parsed_messages").and_return([message])
      end

      it 'should store sample data in test sample (without id) if test does not have a sample' do
        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(1)

        test = TestResult.first
        sample = test.sample
        sample.entity_id.should be_nil

        sample.plain_sensitive_data.should eq("id" => SAMPLE_ID)
        sample.custom_fields.should eq(SAMPLE_CUSTOM_FIELDS)
        sample.indexed_fields.should eq(SAMPLE_INDEXED_FIELDS)
      end

      it 'should merge sample if test has a sample' do
        sample = Sample.make(
          uuid: 'abc', institution: device_message.institution,
          indexed_fields: {"existing_field" => "a value"},
          plain_sensitive_data: {"uid" => SAMPLE_UID},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, device: device

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(1)

        sample = Sample.first

        sample.plain_sensitive_data.should eq(SAMPLE_PII_FIELDS)
        sample.custom_fields.should eq(SAMPLE_CUSTOM_FIELDS)
        sample.indexed_fields.should eq(SAMPLE_INDEXED_FIELDS.merge("existing_field" => "a value"))
      end
    end

    context 'with sample uid' do
      before :each do
        message = parsed_message(TEST_ID)
        clear message, "patient", "encounter"
        device_message.stub("parsed_messages").and_return([message])
      end

      it 'should extract existing data in sample and create the sample entity with id' do
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID},
        )

        sample = Sample.make(
          patient: patient,
          indexed_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(1)
        test = TestResult.first
        sample = test.sample

        test.patient.should eq(patient)
        sample.patient.should eq(patient)

        sample.plain_sensitive_data.should eq(SAMPLE_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        sample.custom_fields.should eq(SAMPLE_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        sample.indexed_fields.should eq(SAMPLE_INDEXED_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should extract existing data in patient and create the patient entity with id' do
        patient = Patient.make(
          institution: device_message.institution,
          indexed_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        sample = Sample.make patient: patient

        TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device

        device_message_processor.process

        TestResult.count.should eq(1)
        Patient.count.should eq(1)
        test = TestResult.first
        patient = test.patient

        patient.plain_sensitive_data.should eq("existing_pii_field" => "existing_pii_field_value")
        patient.custom_fields.should eq("existing_custom_field" => "existing_custom_field_value")
        patient.indexed_fields.should eq("existing_indexed_field" => "existing_indexed_field_value")
      end

      it 'should merge sample with existing sample if sample uid matches' do
        patient = Patient.make institution: device_message.institution

        sample = Sample.make(
          uuid: 'abc', institution: device_message.institution, patient: patient,
          indexed_fields: {"existing_field" => "a value"},
          plain_sensitive_data: {"uid" => SAMPLE_UID},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(1)

        sample = TestResult.first.sample

        sample.plain_sensitive_data.should eq(SAMPLE_PII_FIELDS)
        sample.custom_fields.should eq(SAMPLE_CUSTOM_FIELDS)
        sample.indexed_fields.should eq(SAMPLE_INDEXED_FIELDS.merge("existing_field" => "a value"))
      end

      it 'should create a new sample if the existing sample has a different sample uid' do
        sample = Sample.make(
          uuid: 'abc', institution: device_message.institution,
          plain_sensitive_data: {"uid" => "def9772"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, device: device

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(2)

        sample = TestResult.first.sample
        assert_sample_data sample
      end

      it 'should not destroy existing sample if it has other references' do
        sample = Sample.make(
          uuid: 'abc', institution: device_message.institution,
          plain_sensitive_data: {"uid" => "def9772"},
        )

        test_1 = TestResult.create_and_index test_id: TEST_ID_2, sample: sample, device: device

        device_message_processor.process

        test_2 = TestResult.find_by(test_id: TEST_ID)

        test_1.reload.sample.sample_uid.should eq('def9772')
        test_2.reload.sample.sample_uid.should eq(SAMPLE_UID)
      end

      it "should assign existing sample's patient to the test" do
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"patient_id" => PATIENT_ID},
        )

        Sample.make(
          institution: device_message.institution, patient: patient,
          plain_sensitive_data: {"uid" => SAMPLE_UID},
        )

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(1)
        Patient.count.should eq(1)

        test = TestResult.first
        test.patient.should eq(test.sample.patient)
      end
    end

    context 'without patient id' do
      before :each do
        message = parsed_message(TEST_ID)
        message["patient"]["pii"].delete("id")
        clear message, "sample", "encounter"
        device_message.stub("parsed_messages").and_return([message])
      end

      it 'should merge patient into test patient if test has patient but not sample' do
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID},
          indexed_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: nil, device: device, patient: patient

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(0)
        Patient.count.should eq(1)

        patient = TestResult.first.patient

        patient.plain_sensitive_data.should eq(PATIENT_PII_FIELDS)
        patient.custom_fields.should eq(PATIENT_CUSTOM_FIELDS)
        patient.indexed_fields.should eq(PATIENT_INDEXED_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should merge patient into sample patient if sample has patient' do
        patient = Patient.make(
          plain_sensitive_data: {"id" => PATIENT_ID},
          indexed_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          institution: device_message.institution
        )

        sample = Sample.make(
          institution: device_message.institution, patient: patient,
          plain_sensitive_data: {"uid" => SAMPLE_UID},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(1)
        Patient.count.should eq(1)

        patient = TestResult.first.sample.patient

        patient.plain_sensitive_data.should eq(PATIENT_PII_FIELDS)
        patient.custom_fields.should eq(PATIENT_CUSTOM_FIELDS)
        patient.indexed_fields.should eq(PATIENT_INDEXED_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should store patient data in patient without id if test does not have a sample or patient' do
        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(0)
        Patient.count.should eq(1)

        test = TestResult.first

        test.patient.entity_id.should be_nil
        test.patient.plain_sensitive_data.should eq("dob" => PATIENT_DOB)
        test.patient.custom_fields.should eq(PATIENT_CUSTOM_FIELDS)
        test.patient.indexed_fields.should eq(PATIENT_INDEXED_FIELDS)
      end

      it 'should store patient data in patient if sample is present but doest not have a patient' do
        sample = Sample.make(
          institution: device_message.institution,
          plain_sensitive_data: {"uid" => SAMPLE_UID},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, device: device

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(1)
        Patient.count.should eq(1)

        patient = TestResult.first.sample.patient

        patient.plain_sensitive_data.should eq("dob" => PATIENT_DOB)
        patient.custom_fields.should eq(PATIENT_CUSTOM_FIELDS)
        patient.indexed_fields.should eq(PATIENT_INDEXED_FIELDS)
      end
    end

    context 'with patient id' do
      before :each do
        message = parsed_message(TEST_ID)
        clear message, "sample", "encounter"
        device_message.stub("parsed_messages").and_return([message])
      end

      it 'should extract existing data in test and create the patient entity' do
        patient = Patient.make(
          indexed_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        TestResult.create_and_index(
          test_id: TEST_ID, sample: nil, patient: patient, device: device,
        )

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(0)
        Patient.count.should eq(1)

        patient = TestResult.first.patient

        patient.plain_sensitive_data.should eq(PATIENT_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        patient.custom_fields.should eq(PATIENT_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        patient.indexed_fields.should eq(PATIENT_INDEXED_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should extract existing data in patient and create the patient entity' do
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
          indexed_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
        )

        sample = Sample.make(
          institution: device_message.institution, patient: patient,
          plain_sensitive_data: SAMPLE_PII_FIELDS,
        )

        TestResult.create_and_index test_id: TEST_ID, sample: sample, patient: patient, device: device

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(1)
        Patient.count.should eq(1)

        patient = TestResult.first.sample.patient

        patient.plain_sensitive_data.should eq(PATIENT_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        patient.custom_fields.should eq(PATIENT_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        patient.indexed_fields.should eq(PATIENT_INDEXED_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should merge patient with existing patient if patient id matches' do
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => PATIENT_ID, "existing_pii_field" => "existing_pii_field_value"},
          indexed_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: nil, device: device, patient: patient

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(0)
        Patient.count.should eq(1)

        patient = TestResult.first.patient

        patient.plain_sensitive_data.should eq(PATIENT_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        patient.custom_fields.should eq(PATIENT_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
        patient.indexed_fields.should eq(PATIENT_INDEXED_FIELDS.merge("existing_indexed_field" => "existing_indexed_field_value"))
      end

      it 'should create a new patient if the existing patient has a differente patient id' do
        patient = Patient.make(
          institution: device_message.institution,
          plain_sensitive_data: {"id" => "9000"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: nil, device: device, patient: patient

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(0)
        Patient.count.should eq(2)

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

        test_1.reload.patient.patient_id.should eq('9000')
        test_2.patient.patient_id.should eq(PATIENT_ID)
      end

      it 'should create patient and store reference in test and sample' do
        TestResult.create_and_index test_id: TEST_ID, device: device

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(1)
        Patient.count.should eq(1)

        test = TestResult.first

        test.patient.should eq(test.sample.patient)
      end
    end

    context 'without encounter id' do
      before :each do
        message = parsed_message(TEST_ID)
        message["encounter"]["pii"].delete("id")
        clear message, "patient", "sample"
        device_message.stub("parsed_messages").and_return([message])
      end

      it 'should store encounter data in entity without id if test does not have an encounter' do
        device_message_processor.process

        TestResult.count.should eq(1)
        Encounter.count.should eq(1)

        encounter = TestResult.first.encounter
        encounter.entity_id.should be_nil
        encounter.custom_fields.should eq(ENCOUNTER_CUSTOM_FIELDS)
      end

      it 'should merge encounter if test has an encounter' do
        encounter = Encounter.make(
          uuid: 'ghi', institution: device_message.institution,
          custom_fields: {"existing_field" => "a value"},
          plain_sensitive_data: ENCOUNTER_PII_FIELDS,
        )

        TestResult.create_and_index test_id: TEST_ID, encounter: encounter, device: device

        device_message_processor.process

        TestResult.count.should eq(1)
        Encounter.count.should eq(1)

        encounter = Encounter.first

        encounter.plain_sensitive_data.should eq(ENCOUNTER_PII_FIELDS)
        encounter.custom_fields.should eq(ENCOUNTER_CUSTOM_FIELDS.merge("existing_field" => "a value"))
      end
    end

    context 'with encounter id' do
      before :each do
        message = parsed_message(TEST_ID)
        clear message, "patient", "sample"
        device_message.stub("parsed_messages").and_return([message])
      end

      it 'should extract existing data in encounter and create the encounter entity' do
        encounter = Encounter.make(
          uuid: 'ghi', institution: device_message.institution,
          indexed_fields: {"existing_indexed_field" => "existing_indexed_field_value"},
          custom_fields: {"existing_custom_field" => "existing_custom_field_value"},
          plain_sensitive_data: {"existing_pii_field" => "existing_pii_field_value"},
        )

        TestResult.create_and_index test_id: TEST_ID, sample: nil, device: device, encounter: encounter

        device_message_processor.process

        TestResult.count.should eq(1)
        Sample.count.should eq(0)
        Patient.count.should eq(0)
        Encounter.count.should eq(1)

        encounter = TestResult.first.encounter

        encounter.plain_sensitive_data.should eq(ENCOUNTER_PII_FIELDS.merge("existing_pii_field" => "existing_pii_field_value"))
        encounter.custom_fields.should eq(ENCOUNTER_CUSTOM_FIELDS.merge("existing_custom_field" => "existing_custom_field_value"))
      end

      it "should update encounter if encounter_id changes" do
        old_encounter = Encounter.make(
          uuid: 'ghi', institution: device_message.institution,
          plain_sensitive_data: {"id" => "ANOTHER ID"},
        )

        test = TestResult.create_and_index test_id: TEST_ID, device: device, encounter: old_encounter

        device_message_processor.process

        Encounter.count.should eq(2)

        encounter = Encounter.first
        encounter2 = TestResult.first.encounter
        encounter.should_not eq(encounter2)
      end
    end
  end
end
