require "spec_helper"

describe TestResultIndexer, elasticsearch: true do

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

  let(:test){ TestResult.make(
    sample: sample,
    test_id: '4'
  )}


  let(:test_indexer) { TestResultIndexer.new({
      test_id: "4",
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
    }, test
  )}

  it "should index a document" do
    client = double(:es_client)
    TestResultIndexer.any_instance.stub(:client).and_return(client)
    location = test.device.laboratories.first.location

    client.should_receive(:index).with(
      index: test.device.institution.elasticsearch_index_name,
      type: "test",
      body: {
        start_time: test.created_at.utc.iso8601,
        created_at: test.created_at.utc.iso8601,
        updated_at: test.updated_at.utc.iso8601,
        device_uuid: test.device.uuid,
        uuid: test.uuid,
        location_id: location.geo_id,
        parent_locations: [location.geo_id],
        laboratory_id: test.device.laboratories.first.id,
        institution_id: test.device.institution_id,
        location: {"admin_level_0"=>location.geo_id},
        test_id: "4",
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
      id: "#{test.device.uuid}_4")

    test_indexer.index
  end
end
