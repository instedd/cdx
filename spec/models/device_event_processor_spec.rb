require "spec_helper"

describe DeviceEventProcessor do
  let(:device) {Device.make}
  let(:institution) {device.institution}
  let(:device_event) do
    device_event = DeviceEvent.new(device: device, plain_text_data: 'foo')
    device_event.stub(:parsed_event).and_return({
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
    }.recursive_stringify_keys!.with_indifferent_access)
    device_event.save!
    device_event
  end

  let(:device_event_processor) {DeviceEventProcessor.new(device_event)}

  it "should create a sample" do
    device_event_processor.process

    Sample.count.should eq(1)
    sample = Sample.first
    sample.sample_uid_hash.should eq(EventEncryption.hash "abc4002")

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

  it "should update sample data and existing events" do
    sample_indexed_fields = {
      sample_type: "blood",
      custom_fields: {
        hiv: "positive"
      }
    }.recursive_stringify_keys!
    sample = Sample.make(uuid: 'abc', indexed_fields: sample_indexed_fields, plain_sensitive_data: {sample_uid: 'abc4002'}.recursive_stringify_keys!.with_indifferent_access, institution: device_event.institution)

    event = Event.create_and_index({event_id: "4", assay: "mtb", custom_fields: {concentration: "15%"}}, {sample: sample, event_id: '4'})

    event = Event.create_and_index({event_id: "2", assay: "mtb"}, {sample: sample, event_id: '2'})

    device_event_processor.process

    Sample.count.should eq(1)

    sample = Sample.first

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

    events = all_elasticsearch_events_for(institution)

    events.each do |event|
      event["_source"]["sample_type"].should eq("sputum")
    end
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

  pending "On new event with no sample uid, create event and sample with no uid" do

  end
end
