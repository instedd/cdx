require "spec_helper"

describe DeviceEventProcessor, elasticsearch: true do

  def parsed_event(event_id, params={})
    {
      event: {
        indexed: {
          event_id: event_id,
          assay: "mtb",
          custom_fields: {
            concentration: "15%"
          },
          results: [
            {
              result: "positive",
              condition: "mtb"
            }
          ]
        },
        custom: {
          raw_result: "positivo 15%"
        },
        pii: {
          start_time: "2000/1/1 10:00:00"
        }
      },
      sample: {
        indexed: {
          sample_type: "sputum",
          custom_fields: {
            culture_days: "10"
          }
        },
        custom: {
          datagram: "010100011100"
        },
        pii: {
          sample_uid: "abc4002",
          sample_id: "4002",
          collected_at: "2000/1/1 9:00:00"
        }
      },
      patient: {
        indexed: {
          gender: "male",
          custom_fields: {
            hiv: "positive"
          }
        },
        pii: {
          patient_id: "8000",
          dob: "2000/1/1"
        },
        custom: {
          shirt_color: "blue"
        }
      }
    }.recursive_stringify_keys!.with_indifferent_access.deep_merge(params)
  end

  let(:device) {Device.make}

  let(:institution) {device.institution}

  let(:device_event) do
    device_event = DeviceEvent.new(device: device, plain_text_data: '{}')
    device_event.stub(:parsed_events).and_return([parsed_event("4")])
    device_event.save!
    device_event
  end

  let(:device_event_processor) {DeviceEventProcessor.new(device_event)}

  def assert_sample_data(sample)
    sample.plain_sensitive_data.should eq({
      sample_uid: "abc4002",
      sample_id: "4002",
      collected_at: "2000/1/1 9:00:00"
    }.recursive_stringify_keys!)

    sample.custom_fields.should eq({
      datagram: "010100011100"
    }.recursive_stringify_keys!)

    sample.indexed_fields.should eq({
      sample_type: "sputum",
      custom_fields: {
        culture_days: "10"
      }
    }.recursive_stringify_keys!)
  end

  def assert_patient_data(patient)
    patient.plain_sensitive_data.should eq({
      patient_id: "8000",
      dob: "2000/1/1"
    }.recursive_stringify_keys!)

    patient.custom_fields.should eq({
      shirt_color: "blue"
    }.recursive_stringify_keys!)

    patient.indexed_fields.should eq({
      gender: "male",
      custom_fields: {
        hiv: "positive"
      }
    }.recursive_stringify_keys!)
  end

  it "should create a sample" do
    device_event_processor.process

    Sample.count.should eq(1)
    sample = Sample.first
    sample.sample_uid_hash.should eq(EventEncryption.hash "abc4002")
    assert_sample_data(sample)
    assert_patient_data(sample.patient)
  end

  it "should not update existing events on new sample" do
    device_event_processor.client.should_receive(:bulk).never
    device_event_processor.process

    Sample.count.should eq(1)
  end

  it "should create an event" do
    device_event_processor.process

    Event.count.should eq(1)
    event = Event.first
    event.event_id.should eq('4')

    event.plain_sensitive_data.should eq({
      start_time: "2000/1/1 10:00:00"
    }.recursive_stringify_keys!)

    event.custom_fields.should eq({
      raw_result: "positivo 15%"
    }.recursive_stringify_keys!)
  end

  it "should create multiple events with single sample" do
    device_event.stub(:parsed_events).and_return([parsed_event("4"), parsed_event("5"), parsed_event("6")])
    device_event_processor.process

    Sample.count.should eq(1)

    Event.count.should eq(3)
    Event.pluck(:event_id).should =~ ['4', '5', '6']
    Event.pluck(:sample_id).should eq([Sample.first.id] * 3)

    all_elasticsearch_events_for(device.institution).map {|e| e['_source']['sample_uuid']}.should eq([Sample.first.uuid] * 3)
  end

  it "should update sample data and existing events on new event" do
    sample_indexed_fields = {
      sample_type: "blood"
    }.recursive_stringify_keys!

    patient_indexed_fields = {
      custom_fields: {
        hiv: "positive"
      }
    }.recursive_stringify_keys!

    patient = Patient.make(uuid: 'def', indexed_fields: patient_indexed_fields, plain_sensitive_data: {patient_id: '8000'}.recursive_stringify_keys!.with_indifferent_access, institution: device_event.institution)

    sample = Sample.make(uuid: 'abc', indexed_fields: sample_indexed_fields, plain_sensitive_data: {sample_uid: 'abc4002'}.recursive_stringify_keys!.with_indifferent_access, institution: device_event.institution, patient: patient)

    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "3", assay: "mtb", custom_fields: {concentration: "15%"}}, {sample: sample, event_id: '3', device: device})
    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "2", assay: "mtb"}, {sample: sample, event_id: '2', device: device})

    refresh_indices institution.elasticsearch_index_name

    device_event_processor.process

    Sample.count.should eq(1)
    Patient.count.should eq(1)
    sample = Sample.first
    assert_sample_data(sample)
    assert_patient_data(sample.patient)

    events = all_elasticsearch_events_for(institution)

    events.map { |event| event["_source"]["sample_type"] }.should eq(['sputum'] * 3)
  end

  it "should update sample data and existing events on event update" do
    sample_indexed_fields = {
      sample_type: "blood"
    }.recursive_stringify_keys!

    patient_indexed_fields = {
      custom_fields: {
        hiv: "positive"
      }
    }.recursive_stringify_keys!

    patient = Patient.make(uuid: 'def', indexed_fields: patient_indexed_fields, plain_sensitive_data: {patient_id: '8000'}.recursive_stringify_keys!.with_indifferent_access, institution: device_event.institution)

    sample = Sample.make(uuid: 'abc', indexed_fields: sample_indexed_fields, plain_sensitive_data: {sample_uid: 'abc4002'}.recursive_stringify_keys!.with_indifferent_access, institution: device_event.institution, patient: patient)

    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "4", assay: "mtb", custom_fields: {concentration: "15%"}}, {sample: sample, event_id: '4', device: device})
    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "2", assay: "mtb"}, {sample: sample, event_id: '2', device: device})

    refresh_indices

    device_event_processor.process

    Sample.count.should eq(1)
    Patient.count.should eq(1)
    sample = Sample.first
    assert_sample_data(sample)
    assert_patient_data(sample.patient)

    events = all_elasticsearch_events_for(institution)
    events.map { |event| event["_source"]["sample_type"] }.should eq(['sputum'] * 2)
  end

  it "should not update existing events if sample data indexed fields did not change" do
    sample_indexed_fields = {
      sample_type: "sputum",
      custom_fields: {
        culture_days: "10"
      }
    }.recursive_stringify_keys!

    patient_indexed_fields = {
      gender: "male",
      custom_fields: {
        hiv: "positive"
      }
    }.recursive_stringify_keys!

    patient = Patient.make(uuid: 'def', indexed_fields: patient_indexed_fields, plain_sensitive_data: {patient_id: '8000'}.recursive_stringify_keys!.with_indifferent_access, institution: device_event.institution)
    sample = Sample.make(uuid: 'abc', indexed_fields: sample_indexed_fields, plain_sensitive_data: {sample_uid: 'abc4002'}.recursive_stringify_keys!.with_indifferent_access, institution: device_event.institution, patient: patient)
    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "4", assay: "mtb", custom_fields: {concentration: "15%"}}, {sample: sample, event_id: '4', device: device})
    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "2", assay: "mtb"}, {sample: sample, event_id: '2', device: device})

    refresh_indices

    device_event_processor.client.should_receive(:bulk).never
    device_event_processor.process

    Sample.count.should eq(1)
    Patient.count.should eq(1)
    sample = Sample.first
    assert_sample_data(sample)
    assert_patient_data(sample.patient)
  end

  it "shouldn't update sample from another institution" do
    sample_indexed_fields = {
      sample_type: "sputum",
      custom_fields: {
        hiv: "positive"
      }
    }
    sample = Sample.make(uuid: 'abc', indexed_fields: sample_indexed_fields, plain_sensitive_data: {sample_uid: 'abc4002'})

    device_event_processor.process

    Sample.count.should eq(2)

    sample.reload

    sample.plain_sensitive_data.should eq({
      sample_uid: 'abc4002'
    })

    sample.indexed_fields.should eq({
      sample_type: "sputum",
      custom_fields: {
        hiv: "positive"
      }
    })
  end

  it "should update events with the same event_id and different sample_uid" do
    event = Event.create_and_index({event_id: "4", custom_fields: {concentration: "10%", foo: "bar"}, results: [
            {
              result: "negative",
              condition: "flu"
            },
            {
              result: "pos",
              condition: "mtb1"
            }
          ]}, { event_id: '4', device: device})

    device_event_processor.process

    Sample.count.should eq(1)

    events = all_elasticsearch_events_for(institution)
    events.size.should eq(1)
    events.first["_source"]["assay"].should eq("mtb")
    events.first["_source"]["sample_type"].should eq("sputum")
    events.first["_source"]["custom_fields"]["concentration"].should eq("15%")
    events.first["_source"]["custom_fields"]["foo"].should eq("bar")

    Event.count.should eq(1)
    Event.first.sample_id.should eq(Sample.last.id)
    Event.first.custom_fields.should eq({ "raw_result" => "positivo 15%" })
    Event.first.plain_sensitive_data.should eq({ "start_time" => "2000/1/1 10:00:00" })
  end

  context 'sample and patient entities' do

    context 'without sample uid' do
      before :each do
        event = parsed_event("4")
        event[:sample][:pii].delete(:sample_uid)
        event[:patient][:pii] = {}
        event[:patient][:custom] = {}
        event[:patient][:indexed] = {}
        device_event.stub(:parsed_events).and_return([event])
      end

      it 'should store sample data in event if event does not have a sample' do
        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(0)

        event = Event.first

        event.plain_sensitive_data[:sample].should eq({
          sample_id: "4002",
          collected_at: "2000/1/1 9:00:00"
        }.recursive_stringify_keys!)

        event.custom_fields[:sample].should eq({
          datagram: "010100011100"
        }.recursive_stringify_keys!)

        event.indexed_fields[:sample].should eq({
          sample_type: "sputum",
          custom_fields: {
            culture_days: "10"
          }
        }.recursive_stringify_keys!)
      end

      it 'should merge sample if event has a sample' do
        sample = Sample.make(uuid: 'abc', indexed_fields: {existing_field: 'a value'}.recursive_stringify_keys!, plain_sensitive_data: {sample_uid: 'abc4002'}.recursive_stringify_keys!, institution: device_event.institution)
        event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "4", assay: "mtb"}, {sample: sample, event_id: '4', device: device})

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(1)

        sample = Sample.first

        sample.plain_sensitive_data.should eq({
          sample_uid: "abc4002",
          sample_id: "4002",
          collected_at: "2000/1/1 9:00:00"
        }.recursive_stringify_keys!)

        sample.custom_fields.should eq({
          datagram: "010100011100"
        }.recursive_stringify_keys!)

        sample.indexed_fields.should eq({
          existing_field: "a value",
          sample_type: "sputum",
          custom_fields: {
            culture_days: "10"
          }
        }.recursive_stringify_keys!)
      end
    end

    context 'with sample uid' do
      before :each do
        event = parsed_event("4")
        event[:patient][:pii] = {}
        event[:patient][:custom] = {}
        event[:patient][:indexed] = {}
        device_event.stub(:parsed_events).and_return([event])
      end

      it 'should extract existing data in event and create the sample entity' do
        indexed_fields = {
          sample: {
            existing_indexed_field: 'existing_indexed_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        custom_fields = {
          sample: {
            existing_custom_field: 'existing_custom_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        plain_sensitive_data = {
          sample: {
            existing_pii_field: 'existing_pii_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        patient = Patient.make(plain_sensitive_data: {patient_id: '8000'}.recursive_stringify_keys!.with_indifferent_access, institution: device_event.institution)

        event = Event.create_and_index({event_id: '4', assay: 'mtb'}, {
          sample: nil, event_id: '4', device: device, patient: patient,
          indexed_fields: indexed_fields,
          custom_fields: custom_fields,
          plain_sensitive_data: plain_sensitive_data
        })

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(1)
        event = Event.first
        sample = event.sample

        event.patient.should be_nil
        sample.patient.should eq(patient)

        sample.plain_sensitive_data.should eq({
          sample_uid: "abc4002",
          sample_id: "4002",
          collected_at: "2000/1/1 9:00:00",
          existing_pii_field: 'existing_pii_field_value'
        }.recursive_stringify_keys!)

        sample.custom_fields.should eq({
          datagram: "010100011100",
          existing_custom_field: 'existing_custom_field_value'
        }.recursive_stringify_keys!)

        sample.indexed_fields.should eq({
          sample_type: "sputum",
          existing_indexed_field: 'existing_indexed_field_value',
          custom_fields: {
            culture_days: "10"
          }
        }.recursive_stringify_keys!)

        event.plain_sensitive_data[:sample].should be_nil
        event.custom_fields[:sample].should be_nil
        event.indexed_fields[:sample].should be_nil
      end

      it 'should extract existing patient data in event into the sample entity' do
        indexed_fields = {
          patient: {
            existing_indexed_field: 'existing_indexed_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        custom_fields = {
          patient: {
            existing_custom_field: 'existing_custom_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        plain_sensitive_data = {
          patient: {
            existing_pii_field: 'existing_pii_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        event = Event.create_and_index({event_id: '4', assay: 'mtb'}, {
          sample: nil, event_id: '4', device: device,
          indexed_fields: indexed_fields,
          custom_fields: custom_fields,
          plain_sensitive_data: plain_sensitive_data
        })

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(1)
        event = Event.first
        sample = event.sample

        sample.plain_sensitive_data[:patient].should eq({
          existing_pii_field: 'existing_pii_field_value'
        }.recursive_stringify_keys!)

        sample.custom_fields[:patient].should eq({
          existing_custom_field: 'existing_custom_field_value'
        }.recursive_stringify_keys!)

        sample.indexed_fields[:patient].should eq({
          existing_indexed_field: 'existing_indexed_field_value',
        }.recursive_stringify_keys!)
      end

      it 'should merge sample with existing sample if sample uid matches' do
        indexed_fields = {
          existing_field: 'a value'
        }.recursive_stringify_keys!.with_indifferent_access

        plain_sensitive_data  = {
          sample_uid: 'abc4002'
        }.recursive_stringify_keys!.with_indifferent_access

        sample = Sample.make(uuid: 'abc', indexed_fields: indexed_fields, plain_sensitive_data: plain_sensitive_data, institution: device_event.institution)

        Event.create_and_index(
          {sample_uuid: sample.uuid, event_id: '4', assay: 'mtb'},
          {sample: sample, event_id: '4', device: device}
        )

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(1)

        sample = Event.first.sample

        sample.plain_sensitive_data.should eq({
          sample_uid: "abc4002",
          sample_id: "4002",
          collected_at: "2000/1/1 9:00:00"
        }.recursive_stringify_keys!)

        sample.custom_fields.should eq({
          datagram: "010100011100"
        }.recursive_stringify_keys!)

        sample.indexed_fields.should eq({
          existing_field: "a value",
          sample_type: "sputum",
          custom_fields: {
            culture_days: "10"
          }
        }.recursive_stringify_keys!)
      end

      it 'should create a new sample if the existing sample has a different sample uid' do
        plain_sensitive_data  = {
          sample_uid: 'def9772'
        }.recursive_stringify_keys!.with_indifferent_access

        sample = Sample.make(
          uuid: 'abc',
          plain_sensitive_data: plain_sensitive_data,
          institution: device_event.institution
        )

        Event.create_and_index(
          {sample_uuid: sample.uuid, event_id: '4', assay: 'mtb'},
          {sample: sample, event_id: '4', device: device}
        )

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(1)

        sample = Event.first.sample

        sample.plain_sensitive_data.should eq({
          sample_uid: "abc4002",
          sample_id: "4002",
          collected_at: "2000/1/1 9:00:00"
        }.recursive_stringify_keys!)

        sample.custom_fields.should eq({
          datagram: "010100011100"
        }.recursive_stringify_keys!)

        sample.indexed_fields.should eq({
          sample_type: "sputum",
          custom_fields: {
            culture_days: "10"
          }
        }.recursive_stringify_keys!)
      end

      it 'should not destroy existing sample if it has other references' do
        plain_sensitive_data  = {
          sample_uid: 'def9772'
        }.recursive_stringify_keys!.with_indifferent_access

        sample = Sample.make(
          uuid: 'abc',
          plain_sensitive_data: plain_sensitive_data,
          institution: device_event.institution
        )

        event_1 = Event.create_and_index(
          {sample_uuid: sample.uuid, event_id: '7', assay: 'mtb'},
          {sample: sample, event_id: '7', device: device}
        )

        device_event_processor.process

        event_2 = Event.find_by(event_id: '4')

        event_1.reload.sample.sample_uid.should eq('def9772')
        event_2.reload.sample.sample_uid.should eq('abc4002')
      end
    end

    context 'without patient id' do
      before :each do
        event = parsed_event('4')
        event[:patient][:pii].delete(:patient_id)
        event[:sample][:pii] = {}
        event[:sample][:custom] = {}
        event[:sample][:indexed] = {}
        device_event.stub(:parsed_events).and_return([event])
      end

      it 'should merge patient into event patient if event has patient but not sample' do
        plain_sensitive_data = {
          patient_id: '8000'
        }.recursive_stringify_keys!.with_indifferent_access

        indexed_fields = {
          existing_indexed_field: 'existing_indexed_field_value'
        }.recursive_stringify_keys!.with_indifferent_access

        patient = Patient.make(
          plain_sensitive_data: plain_sensitive_data,
          indexed_fields: indexed_fields,
          institution: device_event.institution
        )

        Event.create_and_index({event_id: '4', assay: 'mtb'}, {
          sample: nil, event_id: '4', device: device, patient: patient
        })

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(0)
        Patient.count.should eq(1)

        patient = Event.first.patient

        patient.plain_sensitive_data.should eq({
          patient_id: "8000",
          dob: "2000/1/1"
        }.recursive_stringify_keys!)

        patient.custom_fields.should eq({
          shirt_color: "blue"
        }.recursive_stringify_keys!)

        patient.indexed_fields.should eq({
          existing_indexed_field: 'existing_indexed_field_value',
          gender: "male",
          custom_fields: {
            hiv: "positive"
          }
        }.recursive_stringify_keys!)
      end

      it 'should merge patient into sample patient if sample has patient' do
        plain_sensitive_data = {
          patient_id: '8000'
        }.recursive_stringify_keys!.with_indifferent_access

        indexed_fields = {
          existing_indexed_field: 'existing_indexed_field_value'
        }.recursive_stringify_keys!.with_indifferent_access

        patient = Patient.make(
          plain_sensitive_data: plain_sensitive_data,
          indexed_fields: indexed_fields,
          institution: device_event.institution
        )

        sample = Sample.make(
          plain_sensitive_data: {sample_uid: 'abc4002'},
          institution: device_event.institution,
          patient: patient
        )

        Event.create_and_index({event_id: '4', assay: 'mtb'}, {
          sample: sample, event_id: '4', device: device
        })

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(1)
        Patient.count.should eq(1)

        patient = Event.first.sample.patient

        patient.plain_sensitive_data.should eq({
          patient_id: "8000",
          dob: "2000/1/1"
        }.recursive_stringify_keys!)

        patient.custom_fields.should eq({
          shirt_color: "blue"
        }.recursive_stringify_keys!)

        patient.indexed_fields.should eq({
          existing_indexed_field: 'existing_indexed_field_value',
          gender: "male",
          custom_fields: {
            hiv: "positive"
          }
        }.recursive_stringify_keys!)
      end

      it 'should store patient data in event if event does not have a sample or patient' do
        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(0)
        Patient.count.should eq(0)

        event = Event.first

        event.plain_sensitive_data[:patient].should eq({
          dob: "2000/1/1"
        }.recursive_stringify_keys!)

        event.custom_fields[:patient].should eq({
          shirt_color: "blue"
        }.recursive_stringify_keys!)

        event.indexed_fields[:patient].should eq({
          gender: "male",
          custom_fields: {
            hiv: "positive"
          }
        }.recursive_stringify_keys!)
      end

      it 'should store patient data in sample if sample is present but doest not have a patient' do
        sample = Sample.make(
          plain_sensitive_data: {sample_uid: 'abc4002'},
          institution: device_event.institution
        )

        Event.create_and_index({event_id: '4', assay: 'mtb'}, {
          sample: sample, event_id: '4', device: device
        })

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(1)
        Patient.count.should eq(0)

        sample = Event.first.sample

        sample.plain_sensitive_data[:patient].should eq({
          dob: "2000/1/1"
        }.recursive_stringify_keys!)

        sample.custom_fields[:patient].should eq({
          shirt_color: "blue"
        }.recursive_stringify_keys!)

        sample.indexed_fields[:patient].should eq({
          gender: "male",
          custom_fields: {
            hiv: "positive"
          }
        }.recursive_stringify_keys!)
      end
    end

    context 'with patient id' do
      before :each do
        event = parsed_event('4')
        event[:sample][:pii] = {}
        event[:sample][:custom] = {}
        event[:sample][:indexed] = {}
        device_event.stub(:parsed_events).and_return([event])
      end

      it 'should extract existing data in event and create the patient entity' do
        indexed_fields = {
          patient: {
            existing_indexed_field: 'existing_indexed_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        custom_fields = {
          patient: {
            existing_custom_field: 'existing_custom_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        plain_sensitive_data = {
          patient: {
            existing_pii_field: 'existing_pii_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        Event.create_and_index({event_id: '4', assay: 'mtb'}, {
          sample: nil, event_id: '4', device: device,
          indexed_fields: indexed_fields,
          custom_fields: custom_fields,
          plain_sensitive_data: plain_sensitive_data
        })

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(0)
        Patient.count.should eq(1)

        patient = Event.first.patient

        patient.plain_sensitive_data.should eq({
          patient_id: "8000",
          dob: "2000/1/1",
          existing_pii_field: 'existing_pii_field_value'
        }.recursive_stringify_keys!)

        patient.custom_fields.should eq({
          shirt_color: "blue",
          existing_custom_field: 'existing_custom_field_value'
        }.recursive_stringify_keys!)

        patient.indexed_fields.should eq({
          existing_indexed_field: 'existing_indexed_field_value',
          gender: "male",
          custom_fields: {
            hiv: "positive"
          }
        }.recursive_stringify_keys!)
      end

      it 'should extract existing data in sample and create the patient entity' do
        indexed_fields = {
          patient: {
            existing_indexed_field: 'existing_indexed_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        custom_fields = {
          patient: {
            existing_custom_field: 'existing_custom_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        plain_sensitive_data = {
          sample_uid: 'abc4002',
          patient: {
            existing_pii_field: 'existing_pii_field_value'
          }
        }.recursive_stringify_keys!.with_indifferent_access

        sample = Sample.make(
          plain_sensitive_data: plain_sensitive_data,
          indexed_fields: indexed_fields,
          custom_fields: custom_fields,
          institution: device_event.institution
        )

        Event.create_and_index({event_id: '4', assay: 'mtb'}, {
          sample: sample, event_id: '4', device: device
        })

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(1)
        Patient.count.should eq(1)

        patient = Event.first.sample.patient

        patient.plain_sensitive_data.should eq({
          patient_id: "8000",
          dob: "2000/1/1",
          existing_pii_field: 'existing_pii_field_value'
        }.recursive_stringify_keys!)

        patient.custom_fields.should eq({
          shirt_color: "blue",
          existing_custom_field: 'existing_custom_field_value'
        }.recursive_stringify_keys!)

        patient.indexed_fields.should eq({
          existing_indexed_field: 'existing_indexed_field_value',
          gender: "male",
          custom_fields: {
            hiv: "positive"
          }
        }.recursive_stringify_keys!)
      end

      it 'should merge patient with existing patient if patient id matches' do
        indexed_fields = {
          existing_indexed_field: 'existing_indexed_field_value'
        }.recursive_stringify_keys!.with_indifferent_access

        custom_fields = {
          existing_custom_field: 'existing_custom_field_value'
        }.recursive_stringify_keys!.with_indifferent_access

        plain_sensitive_data = {
          patient_id: '8000',
          existing_pii_field: 'existing_pii_field_value'
        }.recursive_stringify_keys!.with_indifferent_access

        patient = Patient.make(
          plain_sensitive_data: plain_sensitive_data,
          indexed_fields: indexed_fields,
          custom_fields: custom_fields,
          institution: device_event.institution
        )

        Event.create_and_index({event_id: '4', assay: 'mtb'}, {
          sample: nil, event_id: '4', device: device, patient: patient
        })

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(0)
        Patient.count.should eq(1)

        patient = Event.first.patient

        patient.plain_sensitive_data.should eq({
          patient_id: "8000",
          dob: "2000/1/1",
          existing_pii_field: 'existing_pii_field_value'
        }.recursive_stringify_keys!)

        patient.custom_fields.should eq({
          shirt_color: "blue",
          existing_custom_field: 'existing_custom_field_value'
        }.recursive_stringify_keys!)

        patient.indexed_fields.should eq({
          existing_indexed_field: 'existing_indexed_field_value',
          gender: "male",
          custom_fields: {
            hiv: "positive"
          }
        }.recursive_stringify_keys!)
      end

      it 'should create a new patient if the existing patient has a differente patient id' do
        plain_sensitive_data = {
          patient_id: '9000'
        }.recursive_stringify_keys!.with_indifferent_access

        patient = Patient.make(
          plain_sensitive_data: plain_sensitive_data,
          institution: device_event.institution
        )

        Event.create_and_index({event_id: '4', assay: 'mtb'}, {
          sample: nil, event_id: '4', device: device, patient: patient
        })

        device_event_processor.process

        Event.count.should eq(1)
        Sample.count.should eq(0)
        Patient.count.should eq(1)

        patient = Event.first.patient

        patient.plain_sensitive_data.should eq({
          patient_id: "8000",
          dob: "2000/1/1"
        }.recursive_stringify_keys!)

        patient.custom_fields.should eq({
          shirt_color: "blue"
        }.recursive_stringify_keys!)

        patient.indexed_fields.should eq({
          gender: "male",
          custom_fields: {
            hiv: "positive"
          }
        }.recursive_stringify_keys!)
      end

      it 'should not destroy existing patient if it has other references' do
        plain_sensitive_data  = {
          patient_id: '9000'
        }.recursive_stringify_keys!.with_indifferent_access

        patient = Patient.make(
          plain_sensitive_data: plain_sensitive_data,
          institution: device_event.institution
        )

        event_1 = Event.create_and_index(
          {event_id: '7', assay: 'mtb'},
          {sample: nil, event_id: '7', device: device, patient: patient}
        )

        device_event_processor.process

        event_2 = Event.find_by(event_id: '4')

        event_1.reload.patient.patient_id.should eq('9000')
        event_2.patient.patient_id.should eq('8000')
      end
    end

  end

end
