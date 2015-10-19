require 'spec_helper'
require 'policy_spec_helper'

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

  describe "GET #show" do
    it "returns http success if allowed" do
      i1 = Institution.make
      grant i1.user, user, i1, CREATE_INSTITUTION_ENCOUNTER
      grant i1.user, user, {encounter: i1}, READ_ENCOUNTER

      encounter = Encounter.make institution: i1
      get :show, id: encounter.id
      expect(response).to have_http_status(:success)
    end

    it "returns http forbidden if not allowed" do
      i1 = Institution.make
      encounter = Encounter.make institution: i1
      get :show, id: encounter.id

      expect(response).to have_http_status(:forbidden)
    end

    it "redirects to edit if can edit" do
      i1 = Institution.make
      grant i1.user, user, i1, CREATE_INSTITUTION_ENCOUNTER
      grant i1.user, user, {encounter: i1}, READ_ENCOUNTER
      grant i1.user, user, {encounter: i1}, UPDATE_ENCOUNTER

      encounter = Encounter.make institution: i1
      get :show, id: encounter.id

      expect(response).to redirect_to(edit_encounter_path(encounter))
    end
  end

  describe "GET #edit" do
    it "returns http success if allowed" do
      i1 = Institution.make
      grant i1.user, user, i1, CREATE_INSTITUTION_ENCOUNTER
      grant i1.user, user, {encounter: i1}, UPDATE_ENCOUNTER

      encounter = Encounter.make institution: i1
      get :edit, id: encounter.id
      expect(response).to have_http_status(:success)
    end

    it "returns http forbidden if not allowed" do
      i1 = Institution.make
      encounter = Encounter.make institution: i1
      get :edit, id: encounter.id

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET #institutions" do
    it "returns institutions where the use can create encounters" do
      i1 = Institution.make
      i2 = Institution.make

      grant i1.user, user, i1, CREATE_INSTITUTION_ENCOUNTER
      grant i1.user, user, {testResult: i1}, QUERY_TEST
      grant i2.user, user, {testResult: i2}, QUERY_TEST

      get :institutions

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["total_count"]).to eq(2)

      expect(json_response["institutions"].map(&:with_indifferent_access)).to contain_exactly(institution_json(institution),institution_json(i1))
    end
  end

  describe "POST #create" do
    let(:sample) {
      device = Device.make institution: institution
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'a'}, patient: {id: 'a'})
      Sample.first
    }

    before(:each) {
      post :create, encounter: {
        institution: { uuid: institution.uuid },
        samples: [{ uuid: sample.uuid }],
        test_results: [],
        assays: [{condition: 'mtb', result: 'positive', quantitative: 3}]
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

    it "assigns assays" do
      expect(sample.encounter.core_fields[Encounter::ASSAYS_FIELD]).to eq([{'condition' => 'mtb', 'result' => 'positive', 'quantitative' => 3}])
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
      device = Device.make institution: institution

      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'bab'})
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'bcb'})

      sample = Sample.first

      get :search_sample, institution_uuid: institution.uuid, q: 'a'

      expect(response).to have_http_status(:success)
      expect(response.body).to eq([sample_json(sample)].to_json)
    end

    it "filters sample of selected institution within permission" do
      device1 = Device.make institution: i1 = Institution.make, site: Site.make(institution: i1)
      device2 = Device.make institution: i2 = Institution.make, site: Site.make(institution: i2)
      device3 = Device.make institution: i1, site: Site.make(institution: i1)

      DeviceMessage.create_and_process device: device1, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'bab'})
      DeviceMessage.create_and_process device: device2, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'cac'})
      DeviceMessage.create_and_process device: device3, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'dad'})

      grant device1.institution.user, user, device1.institution, CREATE_INSTITUTION_ENCOUNTER
      grant device2.institution.user, user, device2.institution, CREATE_INSTITUTION_ENCOUNTER

      grant device1.institution.user, user, {testResult: device1}, QUERY_TEST
      grant device2.institution.user, user, {testResult: device2}, QUERY_TEST

      get :search_sample, institution_uuid: device1.institution.uuid, q: 'a'

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(1)
      expect(json_response.first.with_indifferent_access[:entity_id]).to eq("bab")
    end

  end

  describe "GET #search_test" do
    it "returns test_result by test_id" do
      device = Device.make institution: institution

      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"], id: 'bab'})
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"], id: 'bcb'})

      test1 = TestResult.first

      get :search_test, institution_uuid: institution.uuid, q: 'a'

      expect(response).to have_http_status(:success)
      expect(response.body).to eq([test_result_json(test1)].to_json)
    end

    it "filters test_result of selected institution within permission" do
      device1 = Device.make institution: i1 = Institution.make, site: Site.make(institution: i1)
      device2 = Device.make institution: i2 = Institution.make, site: Site.make(institution: i2)
      device3 = Device.make institution: i1, site: Site.make(institution: i1)

      DeviceMessage.create_and_process device: device1, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"], id: 'bab'})
      DeviceMessage.create_and_process device: device2, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"], id: 'cac'})
      DeviceMessage.create_and_process device: device3, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"], id: 'dad'})

      grant device1.institution.user, user, device1.institution, CREATE_INSTITUTION_ENCOUNTER
      grant device2.institution.user, user, device2.institution, CREATE_INSTITUTION_ENCOUNTER

      grant device1.institution.user, user, {testResult: device1}, QUERY_TEST
      grant device2.institution.user, user, {testResult: device2}, QUERY_TEST

      get :search_test, institution_uuid: device1.institution.uuid, q: 'a'

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(1)
      expect(json_response.first.with_indifferent_access[:test_id]).to eq("bab")
    end
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
      device = Device.make institution: institution
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'a'}, patient: {id: 'a'})
      sample_with_encounter = Sample.first
      sample_with_encounter.encounter = Encounter.make
      sample_with_encounter.save!

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
      device = Device.make institution: institution
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'a'}, patient: {id: 'a'})
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'b'}, patient: {id: 'b'})

      sample_with_patient1, sample_with_patient2 = Sample.all.to_a

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

    it "ensure only samples withing permissions can be used" do
      device1 = Device.make institution: i1 = Institution.make, site: Site.make(institution: i1)
      device2 = Device.make institution: i1, site: Site.make(institution: i1)

      DeviceMessage.create_and_process device: device1, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'a'})
      DeviceMessage.create_and_process device: device2, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'b'})
      DeviceMessage.create_and_process device: device2, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'c'})
      sample_a, sample_b, sample_c = Sample.all.to_a

      grant device1.institution.user, user, i1, CREATE_INSTITUTION_ENCOUNTER
      grant device1.institution.user, user, {testResult: device1}, QUERY_TEST

      put :add_sample, sample_uuid: sample_c.uuid, encounter: {
        institution: { uuid: i1.uuid },
        samples: [{uuid: sample_a.uuid}, {uuid: sample_b.uuid}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['encounter']['samples'][0]).to include(sample_json(sample_a))
      expect(json_response['encounter']['samples'].count).to eq(1)
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

    it "ensure only test_results withing permissions can be used" do
      device1 = Device.make institution: i1 = Institution.make, site: Site.make(institution: i1)
      device2 = Device.make institution: i1, site: Site.make(institution: i1)

      DeviceMessage.create_and_process device: device1, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"], id: 'bab'})
      DeviceMessage.create_and_process device: device2, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"], id: 'cac'})
      DeviceMessage.create_and_process device: device2, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"], id: 'dad'})

      grant device1.institution.user, user, device1.institution, CREATE_INSTITUTION_ENCOUNTER
      grant device1.institution.user, user, {testResult: device1}, QUERY_TEST

      test_result_a, test_result_b, test_result_c = TestResult.all.to_a

      put :add_test, test_uuid: test_result_c.uuid, encounter: {
        institution: { uuid: i1.uuid },
        samples: [],
        test_results: [{uuid: test_result_a.uuid}, {uuid: test_result_b.uuid}],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access
      expect(json_response['encounter']['test_results'][0]).to include(test_result_json(test_result_a))
      expect(json_response['encounter']['test_results'].count).to eq(1)
    end
  end

  def institution_json(institution)
    return {
      uuid: institution.uuid,
      name: institution.name,
    }
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
      start_time: test_result.core_fields[TestResult::START_TIME_FIELD].try { |d| d.strftime('%B %e, %Y') },
      assays: test_result.core_fields[TestResult::ASSAYS_FIELD] || [],
      site: {
        name: test_result.device.site.name
      },
      device: {
        name: test_result.device.name
      },
    }.tap do |res|
      if test_result.sample
        res.merge! sample_entity_id: test_result.sample.entity_id
      end
    end
  end
end
