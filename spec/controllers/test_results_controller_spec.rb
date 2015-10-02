require 'spec_helper'
require 'policy_spec_helper'

describe TestResultsController, elasticsearch: true do
  let!(:user)        {User.make}
  let!(:institution) { user.create Institution.make_unsaved }

  let(:laboratory)  { Laboratory.make institution: institution }
  let(:device)      { Device.make institution_id: institution.id, laboratory: laboratory }

  before(:each) {sign_in user}

  let(:other_user)        { User.make }
  let(:other_institution) { Institution.make user_id: other_user.id }
  let(:other_laboratory)  { Laboratory.make institution: other_institution }
  let(:other_device)      { Device.make institution_id: other_institution.id, laboratory: other_laboratory }

  it "should display an empty page when there are no test results" do
    response = get :index
    expect(response.status).to eq(200)
  end

  it "should list test results" do
    test_result = TestResult.create_and_index(
      core_fields: {"results" =>["condition" => "mtb", "result" => :positive]},
      device_messages: [ DeviceMessage.make(device: device) ])

    get :index
    expect(response).to be_success
    expect(assigns(:tests).map{|t| t['test']['uuid']}).to contain_exactly(test_result.uuid)
  end

  it "should load entities for filters" do
    other_user; other_institution; other_laboratory; other_device

    test_result = TestResult.create_and_index(
      core_fields: {"results" =>["condition" => "mtb", "result" => :positive]},
      device_messages: [ DeviceMessage.make(device: device) ])

    get :index
    expect(response).to be_success
    expect(assigns(:institutions).to_a).to contain_exactly(institution)
    expect(assigns(:laboratories).to_a).to contain_exactly(laboratory)
    expect(assigns(:devices).to_a).to      contain_exactly(device)
  end


  describe "show single test result" do

    let!(:owner) { User.make }
    let!(:institution) { Institution.make user_id: owner.id }
    let!(:laboratory)  { Laboratory.make institution: institution }
    let!(:device) { Device.make institution_id: institution.id, laboratory: laboratory }

    let!(:test_result) do
      TestResult.create_and_index(
        core_fields: {"results" =>["condition" => "mtb", "result" => :positive]},
        device_messages: [ DeviceMessage.make(device: device) ]
      )
    end

    let!(:user) { User.make }
    let!(:other_institution) { Institution.make user_id: user.id }
    let!(:other_laboratory)  { Laboratory.make institution: other_institution }
    let!(:other_device) { Device.make institution_id: other_institution.id, laboratory: other_laboratory }

    before(:each) { sign_in user }

    it "should not authorize outsider user" do
      get :show, id: test_result.uuid
      expect(response).to be_forbidden
    end

    it "should authorize user with access to device" do
      grant owner, user, { :test_result => device }, QUERY_TEST

      get :show, id: test_result.uuid
      expect(assigns(:test_result)).to eq(test_result)
      expect(response).to be_success
    end

    it "should authorize user with access to laboratory" do
      grant owner, user, { :test_result => laboratory }, QUERY_TEST

      get :show, id: test_result.uuid
      expect(assigns(:test_result)).to eq(test_result)
      expect(response).to be_success
    end

    it "should authorize user with access to institution" do
      grant owner, user, { :test_result => institution }, QUERY_TEST

      get :show, id: test_result.uuid
      expect(assigns(:test_result)).to eq(test_result)
      expect(response).to be_success
    end
  end
end
