require "spec_helper"

describe EventIndexer, elasticsearch: true do

  let(:sample) do
    sample_indexed_fields = {
      sample_type: "sputum",
      gender: "male",
      custom_fields: {
        culture_days: "10",
        hiv: "positive"
      }
    }
    Sample.make(uuid: 'abc', indexed_fields: sample_indexed_fields)
  end

  let(:event){ Event.make(
    sample: sample,
    event_id: '4'
  )}


  let(:event_indexer) { EventIndexer.new({
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
    }, event
  )}

  it "should index a document" do
    client = double(:es_client)
    EventIndexer.any_instance.stub(:client).and_return(client)

    client.should_receive(:index).with(
      index: event.device.institution.elasticsearch_index_name,
      type: "event",
      body: {
        start_time: event.created_at.utc.iso8601,
        created_at: event.created_at.utc.iso8601,
        updated_at: event.updated_at.utc.iso8601,
        device_uuid: event.device.uuid,
        uuid: event.uuid,
        location_id: event.device.laboratories.first.location.geo_id,
        parent_locations: Location.all.map(&:geo_id),
        laboratory_id: event.device.laboratories.first.id,
        institution_id: event.device.institution_id,
        location: {"admin_level_0"=>"0", "admin_level_1"=>event.device.laboratories.first.location.geo_id},
        event_id: "4",
        sample_uuid: 'abc',
        assay: "mtb",
        sample_type: "sputum",
        gender: "male",
        custom_fields: {
          concentration: "15%",
          culture_days: "10",
          hiv: "positive"
        },
        results: [
          {
            result: "positive",
            condition: "mtb"
          }
        ]
      },
      id: "#{event.device.uuid}_4")

    event_indexer.index
  end
end
