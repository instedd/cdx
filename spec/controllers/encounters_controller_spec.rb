require 'spec_helper'
require 'policy_spec_helper'

RSpec.describe EncountersController, type: :controller, elasticsearch: true do
  let(:institution) { Institution.make }
  let(:user) { institution.user }

  before(:each) { sign_in user }
  let(:default_params) { {context: institution.uuid} }

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

      expect(assigns[:can_update]).to be_falsy
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

      expect(response).to have_http_status(:success)
      expect(assigns[:can_update]).to be_truthy
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
        samples: [{ uuids: sample.uuids }],
        test_results: [],
        assays: [{condition: 'mtb', result: 'positive', quantitative_result: 3}],
        observations: 'Lorem ipsum',
      }.to_json

      sample.reload
    }

    let(:json_response) { JSON.parse(response.body) }
    let(:created_encounter) { Encounter.find(json_response['encounter']['id']) }

    it "succeed" do
      expect(response).to have_http_status(:success)
      expect(json_response['status']).to eq('ok')
    end

    it "assigns samples" do
      expect(sample.encounter).to_not be_nil
    end

    it "returns a json status ok" do
      expect(json_response['status']).to eq('ok')
    end

    it "assigns assays" do
      expect(sample.encounter.core_fields[Encounter::ASSAYS_FIELD]).to eq([{'condition' => 'mtb', 'result' => 'positive', 'quantitative_result' => 3}])
    end

    it "assigns observations" do
      expect(sample.encounter.plain_sensitive_data[Encounter::OBSERVATIONS_FIELD]).to eq('Lorem ipsum')
    end

    it "assigns returns a json with encounter id" do
      expect(created_encounter).to_not be_nil
    end

    it "creates an encounter as non phantom" do
      expect(created_encounter).to_not be_phantom
    end

    it "creates an encounter as non phantom" do
      expect(Time.parse(created_encounter.core_fields["start_time"])).to eq(created_encounter.created_at)
      expect(Time.parse(created_encounter.core_fields["end_time"])).to eq(created_encounter.created_at)
    end
  end

  describe "PUT #update" do
    let(:encounter) { Encounter.make institution: institution }

    let(:sample) {
      device = Device.make institution: institution
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'a'}, patient: {id: 'a'})
      Sample.first
    }

    before(:each) {
      put :update, id: encounter.id, encounter: {
        id: encounter.id,
        institution: { uuid: 'uuid-to-discard' },
        samples: [{ uuids: sample.uuids }],
        test_results: [],
        assays: [{condition: 'mtb', result: 'positive', quantitative_result: 3}],
        observations: 'Lorem ipsum',
      }.to_json

      sample.reload

      encounter.reload
    }

    let(:json_response) { JSON.parse(response.body) }

    it "succeed" do
      expect(response).to have_http_status(:success)
    end

    it "assigns samples" do
      expect(sample.encounter).to eq(encounter)
    end

    it "assigns assays" do
      expect(encounter.core_fields[Encounter::ASSAYS_FIELD]).to eq([{'condition' => 'mtb', 'result' => 'positive', 'quantitative_result' => 3}])
    end

    it "assigns observations" do
      expect(encounter.plain_sensitive_data[Encounter::OBSERVATIONS_FIELD]).to eq('Lorem ipsum')
    end

    it "assigns returns a json status ok" do
      expect(json_response['status']).to eq('ok')
    end

    it "assigns returns a json status ok" do
      expect(json_response['encounter']['id']).to eq(encounter.id)
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
      expect(json_response.first.with_indifferent_access[:entity_ids]).to contain_exactly("bab")
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
      put :add_sample, sample_uuid: test1.sample.uuids[0], encounter: {
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
      put :add_sample, sample_uuid: test1.sample.uuids[0], encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuids: test1.sample.uuids[0]}],
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
      sample_with_encounter.encounter = Encounter.make institution: institution, patient: Patient.last
      sample_with_encounter.save!

      put :add_sample, sample_uuid: sample_with_encounter.uuid, encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuids: test1.sample.uuids[0]}],
        test_results: [{uuid: test1.uuid}],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('error')
      expect(json_response['message']).to eq('Cannot add a test or sample that belongs to a different encounter')
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
        samples: [{uuids: sample_with_patient1.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('error')
      expect(json_response['message']).to eq('Cannot add a test or sample that belongs to a different patient')
    end

    it "it merges data from another patient if both are phantom" do
      device = Device.make institution: institution
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'a'}, patient: {gender: 'male'})
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'b'}, patient: {name: 'Doe'})

      sample_with_patient1, sample_with_patient2 = Sample.all.to_a

      put :add_sample, sample_uuid: sample_with_patient2.uuid, encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuids: sample_with_patient1.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('ok')
      expect(json_response['encounter']['patient']['plain_sensitive_data']).to eq({"custom"=>{}, 'name' => 'Doe'})
      expect(json_response['encounter']['patient']['core_fields']).to eq({'gender' => 'male'})
    end

    it "it merges data from another patient if one of them phantom" do
      device = Device.make institution: institution
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'a'}, patient: {gender: 'male'})
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'b'}, patient: {name: 'Doe', id: 'P10'})

      sample_with_patient1, sample_with_patient2 = Sample.all.to_a

      put :add_sample, sample_uuid: sample_with_patient2.uuid, encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuids: sample_with_patient1.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('ok')
      expect(json_response['encounter']['patient']['plain_sensitive_data']).to eq({'name' => 'Doe', 'id' => 'P10', "custom"=>{}})
      expect(json_response['encounter']['patient']['core_fields']).to eq({'gender' => 'male'})
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
        samples: [{uuids: sample_a.uuids}, {uuids: sample_b.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['encounter']['samples'][0]).to include(sample_json(sample_a))
      expect(json_response['encounter']['samples'].count).to eq(1)
    end

    it "can use existing encounter to add sample" do
      encounter = Encounter.make institution: institution
      device = Device.make institution: institution
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'a'})
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'b'})
      sample_a, sample_b = Sample.all.to_a
      encounter.samples << sample_a
      sample_a.test_results.each {|tr| encounter.test_results << tr }
      encounter.save!

      put :add_sample, sample_uuid: sample_b.uuid, encounter: {
        id: encounter.id,
        institution: { uuid: institution.uuid },
        samples: [{uuids: sample_a.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('ok')
      expect(json_response['encounter']['samples'].count).to eq(2)
      expect(json_response['encounter']['samples'][0]).to include(sample_json(sample_a))
      expect(json_response['encounter']['samples'][1]).to include(sample_json(sample_b))
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

  describe 'PUT #merge_samples' do
    let(:site) { Site.make(institution: institution) }

    let(:samples) do
      3.times.map do |x|
        test = TestResult.make \
          institution: institution,
          device: Device.make(site: site),
          sample_identifier: SampleIdentifier.make(site: site, entity_id: "ID#{x+1}", sample: Sample.make(institution: institution))
        test.sample
      end
    end

    let!(:sample1) { samples[0] }
    let!(:sample3) { samples[2] }

    let!(:sample2) do
      test = TestResult.make \
          institution: institution,
          device: Device.make(site: site),
          sample_identifier: SampleIdentifier.make(site: site, entity_id: "ID2B", sample: samples[1])

      samples[1].reload
    end

    let(:sample_with_encounter) do
      device = Device.make institution: institution, site: site
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'a'}, patient: {id: 'a'})
      sample_with_encounter = Sample.first
      sample_with_encounter.encounter = Encounter.make institution: institution
      sample_with_encounter.save!
      sample_with_encounter
    end

    it "renders json response with merged sample and status ok" do
      put :merge_samples, sample_uuids: [sample1.uuid, sample2.uuid], encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuids: sample1.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('ok')
      expect(json_response['encounter']['samples'].count).to eq(1)

      sample = json_response['encounter']['samples'][0]
      expect(sample['entity_ids']).to contain_exactly('ID1', 'ID2', 'ID2B')
    end

    it "renders json response with merged samples from the same encounter" do
      put :merge_samples, sample_uuids: [sample1.uuid, sample2.uuid], encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuids: sample1.uuids}, {uuids: sample2.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('ok')
      expect(json_response['encounter']['samples'].count).to eq(1)

      sample = json_response['encounter']['samples'][0]
      expect(sample['entity_ids']).to contain_exactly('ID1', 'ID2', 'ID2B')
    end

    it "renders json response with merged samples from the same existing encounter" do
      encounter = Encounter.make institution: institution, samples: [sample1, sample2], patient: nil
      put :merge_samples, sample_uuids: [sample1.uuid, sample2.uuid], encounter: {
        id: encounter.id,
        institution: { uuid: institution.uuid },
        samples: [{uuids: sample1.uuids}, {uuids: sample2.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['status']).to eq('ok')
      expect(json_response['encounter']['samples'].count).to eq(1)

      sample = json_response['encounter']['samples'][0]
      expect(sample['entity_ids']).to contain_exactly('ID1', 'ID2', 'ID2B')
      expect(sample['uuids']).to match_array(sample1.uuids + sample2.uuids)
    end

    it "saves merged samples after a merge sample operation" do
      encounter = Encounter.make institution: institution, samples: [sample1, sample2], patient: nil
      put :merge_samples, sample_uuids: [sample1.uuid, sample2.uuid], encounter: {
        id: encounter.id,
        institution: { uuid: institution.uuid },
        samples: [{uuids: sample1.uuids}, {uuids: sample2.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access
      expect(json_response['status']).to eq('ok')

      put :update, id: encounter.id, encounter: json_response['encounter'].to_json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).with_indifferent_access['status']).to eq('ok')

      expect(encounter.reload).to have(1).sample
      expect(sample1.reload.entity_ids).to contain_exactly('ID1', 'ID2', 'ID2B')
      expect(Sample.find_by_id(sample2.id)).to be_nil
    end


    it "does not persist changes until saved" do
      expect(sample1.reload.entity_ids).to contain_exactly('ID1')
      expect(sample2.reload.entity_ids).to contain_exactly('ID2', 'ID2B')
      expect(sample3.reload.entity_ids).to contain_exactly('ID3')

      put :merge_samples, sample_uuids: [sample1.uuid, sample2.uuid], encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuids: sample1.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(sample1.reload.entity_ids).to contain_exactly('ID1')
      expect(sample2.reload.entity_ids).to contain_exactly('ID2', 'ID2B')
      expect(sample3.reload.entity_ids).to contain_exactly('ID3')
    end

    it "it fails if a sample belongs to another encounter" do
      put :merge_samples, sample_uuids: [sample1.uuid, sample_with_encounter.uuid], encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuids: sample1.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['message']).to eq('Cannot add a test or sample that belongs to a different encounter')
      expect(json_response['status']).to eq('error')
    end

    it "it fails if a sample belongs to a different patient" do
      device = Device.make institution: institution
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'SWP_ID1'}, patient: {id: 'a'})
      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'SWP_ID2'}, patient: {id: 'b'})

      sample_with_patient1, sample_with_patient2 = Sample.last(2)

      expect(sample_with_patient1.patient).to eq(Patient.find_by_entity_id('a', institution_id: institution.id))
      expect(sample_with_patient2.patient).to eq(Patient.find_by_entity_id('b', institution_id: institution.id))

      put :merge_samples, sample_uuids: [sample_with_patient1.uuid, sample_with_patient2.uuid], encounter: {
        institution: { uuid: institution.uuid },
        samples: [{uuids: sample_with_patient1.uuids}],
        test_results: [],
      }.to_json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body).with_indifferent_access

      expect(json_response['message']).to eq('Cannot add a test or sample that belongs to a different patient')
      expect(json_response['status']).to eq('error')
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
      uuids: sample.uuids,
      entity_ids: sample.entity_ids,
      uuid: sample.uuids.first
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
        res.merge! sample_entity_ids: test_result.sample.entity_ids
      end
    end
  end
end
