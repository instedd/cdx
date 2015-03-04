require "spec_helper"

describe DeviceEventProcessor do

  let(:device_event) do
    device_event = DeviceEvent.new(device: Device.make, plain_text_data: 'foo')
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
  end
end
