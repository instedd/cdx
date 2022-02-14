require 'spec_helper'

describe Api::FiltersController do
  let(:user) { User.make! }
  let!(:institution) { Institution.make!(user: user) }

  before(:each) { sign_in user }

  it "list filters" do
    filter = Filter.make!(user: user, query: { site: 1 })

    get :index, format: :json
    expect(response.body).to eq([filter].to_json)
  end
end
