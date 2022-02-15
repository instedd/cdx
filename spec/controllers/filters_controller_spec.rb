require 'spec_helper'

describe FiltersController do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
    @filter = Filter.make! user: @user, query: { site: 1 }
  end

  before(:each) { sign_in user }
  let(:default_params) { {context: institution.uuid} }

  it "list filters" do
    get :index, format: :json
    expect(response.body).to eq([filter].to_json)
  end
end
