require 'spec_helper'

describe DevicesController do
  let(:institution) {Institution.make}
  let(:user) {institution.user}
  before(:each) {sign_in user}

  it "device is created if name is provided" do
    post :create, {"institution_id" => institution.id, "device" => {"name" => "D1"}}
    Device.count.should eq(1)
  end

  it "device without name is not created" do
    post :create, {"institution_id" => institution.id, "device" => {"name" => ""}}
    Device.count.should eq(0)
  end

end
