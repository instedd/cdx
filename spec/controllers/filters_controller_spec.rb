require 'spec_helper'

describe FiltersController do
  let(:user) { User.make! }
  let!(:institution) { Institution.make! user: user }
  let!(:filter) { Filter.make! user: user, query: { site: 1 } }
  before(:each) { sign_in user }
  let(:default_params) { {context: institution.uuid} }

  it "list filters" do
    get :index, format: :json
    expect(response.body).to eq([filter].to_json)
  end
end
