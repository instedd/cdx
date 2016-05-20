require "spec_helper"

describe TestResultIndexer, elasticsearch: true do

  let(:institution) do
    Institution.make
  end

  let(:patient) do
    Patient.make(uuid: 'abc', core_fields: { 'gender' => 'male' }, custom_fields: { 'hiv' => 'positive' }, institution: institution)
  end

  let(:encounter) do
    Encounter.make(patient: patient, core_fields: {}, custom_fields: { 'status' => 'completed' }, institution: institution)
  end

  let(:sample) do
    Sample.make(patient: patient, encounter: encounter, core_fields: { 'type' => 'sputum' }, custom_fields: { 'culture_days' => '10' }, institution: institution)
  end

  let(:sample_identifier) do
    SampleIdentifier.make(sample: sample, uuid: 'abc')
  end

  let(:device) do
    Device.make(institution: institution)
  end

  let(:test) do
    TestResult.make(
      device: device,
      sample_identifier: sample_identifier,
      patient: patient,
      encounter: encounter,
      institution: institution,
      test_id: '4',
      custom_fields: {
        "concentration" => "15%"
      },
      core_fields: {
        "id" => "4",
        "name" => "mtb",
        "assays" => [
          {
            "result" => "positive",
            "name" => "mtb"
          }
        ]
      })
  end

  let(:test_indexer) { TestResultIndexer.new(test)}

  it "should index a document" do
    client = double(:es_client)
    allow_any_instance_of(TestResultIndexer).to receive(:client).and_return(client)
    location = test.device.site.location

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
          "uuid" => ['abc'],
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
        "encounter" => {
          'uuid' => encounter.uuid,
          'user_email' => institution.user.email,
          'custom_fields' => {
            'status' => 'completed'
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
        "site" => {
          "uuid" => test.device.site.uuid,
          "path" => [test.device.site.uuid],
        },
        "institution" => {
          "uuid" => test.device.institution.uuid
        }
      },
      id: test.uuid)
    expect(client).to receive(:percolate).and_return({"matches" => []})

    test_indexer.index
  end
end
