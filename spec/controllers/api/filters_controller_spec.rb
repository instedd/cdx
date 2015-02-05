require 'spec_helper'

describe Api::FiltersController do
  let(:user) { User.make }
  let!(:filter) { user.filters.make query: { laboratory: 1 } }
  before(:each) { sign_in user }

  it "list filters" do
    get :index
    response.body.should eq([filter].to_json)
  end
end
