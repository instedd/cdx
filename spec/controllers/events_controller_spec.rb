require 'spec_helper'

describe EventsController do
  let(:user) {User.make}
  before(:each) {sign_in user}

  it "should display an empty page when there are no events" do
    response = get :index
    response.status.should eq(200)
  end
end
