require 'spec_helper'

describe Api::FiltersController do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
  end

  before(:each) { sign_in user }

  it "list filters" do
    filter = Filter.make!(user: user, query: { site: 1 })

    get :index, format: :json
    expect(response.body).to eq([filter].to_json)
  end
end
