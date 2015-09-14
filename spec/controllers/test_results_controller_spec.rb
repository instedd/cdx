require 'spec_helper'

describe TestResultsController do
  let(:user) {User.make}
  before(:each) {sign_in user}
  let!(:institution) { user.create Institution.make_unsaved }

  it "should display an empty page when there are no test results" do
    response = get :index
    expect(response.status).to eq(200)
  end
end
