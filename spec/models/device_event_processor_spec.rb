require "spec_helper"

describe DeviceEventProcessor do

  let(:device) {Device.make}

  let(:institution) {device.institution}

  let(:device_event) do
    device_event = DeviceEvent.new(device: device, plain_text_data: '{}')
    device_event.stub(:parsed_events).and_return([{
      event: {
        indexed: {
          event_id: "4",
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
    }.recursive_stringify_keys!.with_indifferent_access])
    device_event.save!
    device_event
  end

  let(:device_event_processor) {DeviceEventProcessor.new(device_event)}

  def assert_sample_data(sample)
    sample.plain_sensitive_data.should eq({
      patient_id: "8000",
      dob: "2000/1/1",
      sample_uid: "abc4002",
      sample_id: "4002",
      collected_at: "2000/1/1 9:00:00"
    }.recursive_stringify_keys!)

    sample.custom_fields.should eq({
      datagram: "010100011100",
      shirt_color: "blue"
    }.recursive_stringify_keys!)

    sample.indexed_fields.should eq({
      sample_type: "sputum",
      gender: "male",
      custom_fields: {
        culture_days: "10",
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

  it "should update sample data and existing events on new event" do
    sample_indexed_fields = {
      sample_type: "blood",
      custom_fields: {
        hiv: "positive"
      }
    }.recursive_stringify_keys!

    sample = Sample.make(uuid: 'abc', indexed_fields: sample_indexed_fields, plain_sensitive_data: {sample_uid: 'abc4002'}.recursive_stringify_keys!.with_indifferent_access, institution: device_event.institution)

    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "3", assay: "mtb", custom_fields: {concentration: "15%"}}, {sample: sample, event_id: '3', device: device})
    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "2", assay: "mtb"}, {sample: sample, event_id: '2', device: device})

    refresh_indices institution.elasticsearch_index_name

    device_event_processor.process

    Sample.count.should eq(1)
    sample = Sample.first
    assert_sample_data(sample)

    events = all_elasticsearch_events_for(institution)
    events.map { |event| event["_source"]["sample_type"] }.should eq(['sputum'] * 3)
  end

  it "should update sample data and existing events on event update" do
    sample_indexed_fields = {
      sample_type: "blood",
      custom_fields: {
        hiv: "positive"
      }
    }.recursive_stringify_keys!

    sample = Sample.make(uuid: 'abc', indexed_fields: sample_indexed_fields, plain_sensitive_data: {sample_uid: 'abc4002'}.recursive_stringify_keys!.with_indifferent_access, institution: device_event.institution)

    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "4", assay: "mtb", custom_fields: {concentration: "15%"}}, {sample: sample, event_id: '4', device: device})
    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "2", assay: "mtb"}, {sample: sample, event_id: '2', device: device})

    refresh_indices

    device_event_processor.process

    Sample.count.should eq(1)
    sample = Sample.first
    assert_sample_data(sample)

    events = all_elasticsearch_events_for(institution)
    events.map { |event| event["_source"]["sample_type"] }.should eq(['sputum'] * 2)
  end

  it "should not update existing events if sample data indexed fields did not change" do
    sample_indexed_fields = {
      sample_type: "sputum",
      gender: "male",
      custom_fields: {
        culture_days: "10",
        hiv: "positive"
      }
    }.recursive_stringify_keys!

    sample = Sample.make(uuid: 'abc', indexed_fields: sample_indexed_fields, plain_sensitive_data: {sample_uid: 'abc4002'}.recursive_stringify_keys!.with_indifferent_access, institution: device_event.institution)
    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "4", assay: "mtb", custom_fields: {concentration: "15%"}}, {sample: sample, event_id: '4', device: device})
    event = Event.create_and_index({sample_uuid: sample.uuid, event_id: "2", assay: "mtb"}, {sample: sample, event_id: '2', device: device})

    refresh_indices

    device_event_processor.client.should_receive(:bulk).never
    device_event_processor.process

    Sample.count.should eq(1)
    sample = Sample.first
    assert_sample_data(sample)
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

    Sample.count.should eq(2)

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

  context "on event with no sample uid" do

    let(:device_event) do
      device_event = DeviceEvent.new(device: device, plain_text_data: 'foo')
      device_event.stub(:parsed_events).and_return([{
        event: {
          indexed: {
            event_id: "4",
            assay: "mtb",
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
      }.recursive_stringify_keys!.with_indifferent_access])
      device_event.save!
      device_event
    end

    it "should create sample with no uid" do
      device_event_processor.process

      Sample.count.should eq(1)
      sample = Sample.first
      sample.sample_uid_hash.should be_blank

      sample.plain_sensitive_data.should eq({
        patient_id: "8000",
        dob: "2000/1/1",
        sample_id: "4002",
        collected_at: "2000/1/1 9:00:00"
      }.recursive_stringify_keys!)

      sample.custom_fields.should eq({
        datagram: "010100011100",
        shirt_color: "blue"
      }.recursive_stringify_keys!)

      sample.indexed_fields.should eq({
        sample_type: "sputum",
        gender: "male",
        custom_fields: {
          culture_days: "10",
          hiv: "positive"
        }
      }.recursive_stringify_keys!)
    end

    it "should create event linked to sample without uid" do
      device_event_processor.process

      Sample.count.should eq(1)
      sample = Sample.first

      events = all_elasticsearch_events_for(institution)
      events.size.should eq(1)
      events.first["_source"]['sample_uuid'].should eq(sample.uuid)
    end

  end


end
