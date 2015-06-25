require "spec_helper"

describe TestResultIndexer, elasticsearch: true do

  let(:sample) do
    sample_indexed_fields = {
      sample: {
        type: "sputum",
        custom_fields: {
          culture_days: "10"
        }
      },
      patient: {
        gender: "male",
        custom_fields: {
          hiv: "positive"
        }
      }
    }
    Sample.make(uuid: 'abc', indexed_fields: sample_indexed_fields.with_indifferent_access)
  end

  let(:test){ TestResult.make(
    sample: sample,
    test_id: '4',
    indexed_fields: {
      test: {
        id: "4",
        name: "mtb",
        custom_fields: {
          concentration: "15%"
        },
        assays: [
          {
            qualitative_result: "positive",
            name: "mtb"
          }
        ]
      }
    }.with_indifferent_access
  )}

  let(:test_indexer) { TestResultIndexer.new(test)}

  it "should index a document" do
    client = double(:es_client)
    TestResultIndexer.any_instance.stub(:client).and_return(client)
    location = test.device.laboratories.first.location

    client.should_receive(:index).with(
      index: test.device.institution.elasticsearch_index_name,
      type: "test",
      body: {
        test: {
          id: "4",
          name: "mtb",
          custom_fields: {
            concentration: "15%",
          },
          assays: [
            {
              qualitative_result: "positive",
              name: "mtb"
            }
          ],
          reported_time: test.created_at.utc.iso8601,
          updated_time: test.updated_at.utc.iso8601,
          uuid: test.uuid
        },
        sample: {
          type: "sputum",
          uuid: 'abc',
          custom_fields: {
            culture_days: "10",
          }
        },
        patient: {
          gender: "male",
          custom_fields: {
            hiv: "positive"
          }
        },
        location: {
          id: location.geo_id,
          parents: [location.geo_id],
          admin_levels: {"admin_level_0"=>location.geo_id},
          lat: location.lat,
          lng: location.lng
        },
        device: {
          uuid: test.device.uuid,
          laboratory_id: test.device.laboratories.first.id,
          institution_id: test.device.institution_id
        }
      }.recursive_stringify_keys!,
      id: "#{test.device.uuid}_4")

    test_indexer.index
  end
end
