require 'spec_helper'

RSpec.describe EncountersController, type: :controller do
  let(:institution) { Institution.make }
  let(:user) { institution.user }

  before(:each) { sign_in user }

  describe "GET #new" do
    it "returns http success" do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    let(:sample) { Sample.make institution: institution }

    before(:each) {
      post :create, encounter: {
        institution: { uuid: institution.uuid },
        samples: [{ uuid: sample.uuid }],
        test_results: []
      }.to_json

      sample.reload
    }

    let(:json_response) { JSON.parse(response.body) }

    it "succeed" do
      expect(response).to have_http_status(:success)
    end

    it "assigns samples" do
      expect(sample.encounter).to_not be_nil
    end

    it "assigns returns a json status ok" do
      expect(json_response['status']).to eq('ok')
    end

    it "assigns returns a json with encounter id" do
      encounter = Encounter.find(json_response['encounter']['id'])
      expect(encounter).to_not be_nil
    end
  end

  describe "GET #search_sample" do
    it "returns sample by entity id" do
      sample = Sample.make entity_id: 'bab', institution: institution
      Sample.make entity_id: 'bcb', institution: institution

      get :search_sample, institution_uuid: institution.uuid, q: 'a'

      expect(response).to have_http_status(:success)
      expect(response.body).to eq([sample_json(sample)].to_json)
    end

    pending "filters sample of selected institution"
  end

  describe "GET #search_test" do
    it "returns test_result by test_id" do
      test1 = TestResult.make test_id: 'bab', institution: institution, device: Device.make
      TestResult.make test_id: 'bcb', institution: institution

      get :search_test, institution_uuid: institution.uuid, q: 'a'

      expect(response).to have_http_status(:success)
      expect(response.body).to eq([test_result_json(test1)].to_json)
    end

    pending "filters test_result of selected institution"
  end

  describe "PUT #add_sample" do
    let(:test1) { TestResult.make institution: institution, device: Device.make(site: Site.make(institution: institution)) }

    it "renders json response with filled encounter and status ok" do
      put :add_sample, sample_uuid: test1.sample.uuid, encounter: {
        institution: { uuid: institution.uuid },
        samples: [],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('ok')
      expect(json_response['encounter']['samples'][0]).to include(sample_json(test1.sample))
      expect(json_response['encounter']['samples'].count).to eq(1)

      expect(json_response['encounter']['test_results'][0]).to include(test_result_json(test1))
      expect(json_response['encounter']['test_results'].count).to eq(1)
    end

    it "does not add sample if present" do
      put :add_sample, sample_uuid: test1.sample.uuid, encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuid: test1.sample.uuid}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('ok')
      expect(json_response['encounter']['samples'][0]).to include(sample_json(test1.sample))
      expect(json_response['encounter']['samples'].count).to eq(1)

      expect(json_response['encounter']['test_results'][0]).to include(test_result_json(test1))
      expect(json_response['encounter']['test_results'].count).to eq(1)
    end

    it "it returns json status error if failed due to other encounter" do
      sample_with_encounter = Sample.make institution: institution, encounter: Encounter.make

      put :add_sample, sample_uuid: sample_with_encounter.uuid, encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuid: test1.sample.uuid}],
        test_results: [{uuid: test1.uuid}],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('error')
      expect(json_response['message']).to eq('Unable to add sample that already belongs to other encounter')
      expect(json_response['encounter']['samples'][0]).to include(sample_json(test1.sample))
      expect(json_response['encounter']['samples'].count).to eq(1)

      expect(json_response['encounter']['test_results'][0]).to include(test_result_json(test1))
      expect(json_response['encounter']['test_results'].count).to eq(1)
    end

    it "it returns json status error if failed due to other patient" do
      sample_with_patient1 = Sample.make institution: institution, patient: Patient.make
      sample_with_patient2 = Sample.make institution: institution, patient: Patient.make

      put :add_sample, sample_uuid: sample_with_patient2.uuid, encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuid: sample_with_patient1.uuid}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('error')
      expect(json_response['message']).to eq('Unable to add sample of multiple patients')
    end

  end

  describe "PUT #add_test" do
    let(:test1) { TestResult.make institution: institution, device: Device.make(site: Site.make(institution: institution)) }

    it "renders json response with filled encounter and status ok" do
      put :add_test, test_uuid: test1.uuid, encounter: {
        institution: { uuid: institution.uuid },
        samples: [],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('ok')
      expect(json_response['encounter']['samples'][0]).to include(sample_json(test1.sample))
      expect(json_response['encounter']['samples'].count).to eq(1)

      expect(json_response['encounter']['test_results'][0]).to include(test_result_json(test1))
      expect(json_response['encounter']['test_results'].count).to eq(1)
    end
  end

  def sample_json(sample)
    return {
      uuid: sample.uuid,
      entity_id: sample.entity_id,
    }
  end

  def test_result_json(test_result)
    return {
      uuid: test_result.uuid,
      test_id: test_result.test_id,
      name: test_result.core_fields[TestResult::NAME_FIELD],
      sample_entity_id: test_result.sample.entity_id,
      start_time: test_result.core_fields[TestResult::START_TIME_FIELD].try { |d| d.strftime('%B %e, %Y') },
      assays: [],
      site: {
        name: test_result.device.site.name
      },
      device: {
        name: test_result.device.name
      },
    }
  end
end
