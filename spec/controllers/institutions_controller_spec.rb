require 'spec_helper'

describe InstitutionsController do
  let(:user) {User.make}
  before(:each) {sign_in user}

  it "institution is created if name is provided" do
    post :create, {"institution" => {"name" => "foo"}}
    expect(Institution.count).to eq(1)
  end

  it "institutions without name are not created" do
    post :create, {"institution" => {"name" => ""}}
    expect(Institution.count).to eq(0)
  end

end
