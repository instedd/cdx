require 'spec_helper'

RSpec.describe EncountersController, type: :controller do
  let(:institution) {Institution.make}
  let(:user) {institution.user}

  before(:each) {sign_in user}

  describe "GET #new" do
    it "returns http success" do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

end
