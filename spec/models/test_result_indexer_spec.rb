require "spec_helper"

describe TestResultIndexer, elasticsearch: true do

  let(:patient) do
    patient_core_fields = {
      "gender" => "male",
      "custom_fields" => {
        "hiv" => "positive"
      }
    }
    Patient.make(uuid: 'abc', core_fields: patient_core_fields)
  end

  let(:sample) do
    sample_core_fields = {
      "type" => "sputum",
      "custom_fields" => {
        "culture_days" => "10"
      }
    }
    Sample.make(uuid: 'abc', patient: patient, core_fields: sample_core_fields)
  end

  let(:test){ TestResult.make(
    "sample" => sample,
    "patient" => patient,
    "test_id" => '4',
    "core_fields" => {
      "id" => "4",
      "name" => "mtb",
      "custom_fields" => {
        "concentration" => "15%"
      },
      "assays" => [
        {
          "result" => "positive",
          "name" => "mtb"
        }
      ]
    }
  )}

  let(:test_indexer) { TestResultIndexer.new(test)}

  it "should index a document" do
    client = double(:es_client)
    allow_any_instance_of(TestResultIndexer).to receive(:client).and_return(client)
    location = test.device.laboratory.location

    expect(client).to receive(:index).with(
      index: Cdx::Api.index_name,
      type: "test",
      body: {
        "test" => {
          "id" => "4",
          "name" => "mtb",
          "custom_fields" => {
            "concentration" => "15%",
          },
          "assays" => [
            {
              "result" => "positive",
              "name" => "mtb"
            }
          ],
          "reported_time" => test.created_at.utc.iso8601,
          "updated_time" => test.updated_at.utc.iso8601,
          "uuid" => test.uuid
        },
        "sample" => {
          "type" => "sputum",
          "uuid" => 'abc',
          "custom_fields" => {
            "culture_days" => "10",
          }
        },
        "patient" => {
          "uuid" => patient.uuid,
          "gender" => "male",
          "custom_fields" => {
            "hiv" => "positive"
          }
        },
        "location" => {
          "id" => location.geo_id,
          "parents" => [location.geo_id],
          "admin_levels" => {"admin_level_0"=>location.geo_id},
          "lat" => location.lat,
          "lng" => location.lng
        },
        "device" => {
          "uuid" => test.device.uuid,
          "model" => test.device.device_model.name,
          "serial_number" => test.device.serial_number
        },
        "laboratory" => {
          "uuid" => test.device.laboratory.uuid
        },
        "institution" => {
          "uuid" => test.device.institution.uuid
        }
      },
      id: "#{test.device.uuid}_4")
    expect(client).to receive(:percolate).and_return({"matches" => []})

    test_indexer.index
  end
end
