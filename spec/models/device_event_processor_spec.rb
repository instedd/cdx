require "spec_helper"

describe DeviceEventProcessor do
  let(:device) {Device.make}
  let(:device_event) do
    device_event = DeviceEvent.new(device: device, plain_text_data: 'foo')
    device_event.stub(:parsed_event).and_return({
      event: {
        indexed: {
          event_id: "4",
          assay: "mtb",
          custom_fields: {
            concentration: "15%"
          }
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

  it "should index a document" do
    sample_indexed_fields = {
      sample_type: "sputum",
      gender: "male",
      custom_fields: {
        culture_days: "10",
        hiv: "positive"
      }
    }
    event = Event.create!(
      device_events: [device_event],
      sample: Sample.make(uuid: 'abc', indexed_fields: sample_indexed_fields),
      event_id: '4')

    client = double(:es_client)
    device_event_processor.should_receive(:client).and_return(client)

    client.should_receive(:index).with(
      index: device.institution.elasticsearch_index_name,
      type: "event",
      body: {
        start_time: event.created_at.utc.iso8601,
        created_at: event.created_at.utc.iso8601,
        updated_at: event.updated_at.utc.iso8601,
        device_uuid: device.secret_key,
        uuid: event.uuid,
        location_id: device.laboratories.first.location.geo_id,
        parent_locations: Location.all.map(&:geo_id),
        laboratory_id: device.laboratories.first.id,
        institution_id: device.institution_id,
        location: {"admin_level_0"=>"0", "admin_level_1"=>device.laboratories.first.location.geo_id},
        event_id: "4",
        sample_uuid: 'abc',
        assay: "mtb",
        sample_type: "sputum",
        gender: "male",
        custom_fields: {
          concentration: "15%",
          culture_days: "10",
          hiv: "positive"
        }
      }.recursive_stringify_keys!,
      id: "#{device.secret_key}_4")

    device_event_processor.index_document event
  end
end
