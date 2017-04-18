require "spec_helper"

describe EncounterIndexer, elasticsearch: true do

  let(:institution) do
    Institution.make
  end

  let(:site) do
    Site.make institution: institution
  end

  let(:patient) do
    Patient.make(uuid: 'abc', core_fields: { 'gender' => 'male' }, custom_fields: { 'hiv' => 'positive' }, institution: institution)
  end

  let(:encounter) do
    Encounter.make(patient: patient, core_fields: { 'start_time' => DateTime.new(2015,1,1,0,0,0).utc.iso8601, 'diagnosis' => [{ "condition" => "mtb", "name" => "mtb", "result" => "negative", "quantitative_result" => "20"}] }, custom_fields: { 'status' => 'completed' }, plain_sensitive_data: { 'observations' => 'Diagnosis positive'}, institution: institution)
  end

  let(:encounter_indexer) { EncounterIndexer.new(encounter)}

  it "should index a document" do
    client = double(:es_client)
    allow_any_instance_of(EncounterIndexer).to receive(:client).and_return(client)

    expect(client).to receive(:index).with(
      index: Cdx::Api.index_name,
      type: "encounter",
      body: {
        "institution" => {
          "uuid" => institution.uuid
        },
        "site" => {
          "uuid" => site.uuid,
          "path" => [site.uuid]
        },
        "encounter" => {
          'start_time' => DateTime.new(2015,1,1,0,0,0).utc.iso8601,
          'user_email' => institution.user.email,
          'diagnosis' => [
            { "condition" => "mtb", "name" => "mtb", "result" => "negative", "quantitative_result" => "20"}
          ],
          'custom_fields' => {
            'status' => 'completed'
          },
          'uuid' => encounter.uuid
        },
        "patient" => {
          "uuid" => patient.uuid,
          "gender" => "male",
          "custom_fields" => {
            "hiv" => "positive"
          }
        }
      },
      id: encounter.uuid)

    encounter_indexer.index
  end
end
