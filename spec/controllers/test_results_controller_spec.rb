require 'spec_helper'
require 'policy_spec_helper'

describe TestResultsController, elasticsearch: true do
  let(:user) {User.make}
  before(:each) {sign_in user}
  let!(:institution) { user.create Institution.make_unsaved }

  it "should display an empty page when there are no test results" do
    response = get :index
    expect(response.status).to eq(200)
  end


  describe "show test_result authorize_test_result" do
    let!(:owner) { User.make }
    let!(:institution) { Institution.make user_id: owner.id }
    let!(:laboratory)  { Laboratory.make institution: institution }
    let!(:device) { Device.make institution_id: institution.id, laboratory: laboratory }

    let!(:test_result) {
      TestResult.create_and_index(
        core_fields: {"results" =>["condition" => "mtb", "result" => :positive]},
        device_messages: [ DeviceMessage.make(device: device) ]
      )
    }

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
      grant owner, user, device, QUERY_TEST

      get :show, id: test_result.uuid
      expect(response).to be_success
    end

    it "should authorize user with access to laboratory" do
      grant owner, user, laboratory, QUERY_TEST

      get :show, id: test_result.uuid
      expect(response).to be_success
    end

    it "should authorize user with access to institution" do
      grant owner, user, institution, QUERY_TEST

      get :show, id: test_result.uuid
      expect(response).to be_success
    end
  end
end
