require 'spec_helper'

RSpec.describe PatientsController, type: :controller do
  let!(:institution) {Institution.make}
  let!(:user)        {institution.user}
  before(:each) {sign_in user}
  let(:default_params) { {context: institution.uuid} }

  context "index" do
    it "should be accessible by institution owner" do
      get :index
      expect(response).to be_success
    end
  end
end
