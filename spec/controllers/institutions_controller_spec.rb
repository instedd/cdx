require 'spec_helper'

describe InstitutionsController do
  let(:user) {User.make}
  before(:each) {sign_in user}

  context "index" do

    let!(:institution)   { user.institutions.make }
    let!(:other_institution) { Institution.make }

    it "should list insitutions" do
      institution2 = user.institutions.make
      get :index
      expect(response).to be_success
      expect(assigns(:institutions)).to contain_exactly(institution, institution2)
    end

    it "should redirect to edit institution if there is only one institution" do
      get :index
      expect(response).to be_redirect
    end

  end

  context "create" do

    it "institution is created if name is provided" do
      post :create, {"institution" => {"name" => "foo"}}
      expect(Institution.count).to eq(1)
    end

    it "institutions without name are not created" do
      post :create, {"institution" => {"name" => ""}}
      expect(Institution.count).to eq(0)
    end

    it "sets the newly created institution in context (#796)" do
      post :create, {"institution" => {"name" => "foo"}}
      expect(user.reload.last_navigation_context).to eq(Institution.last.uuid)
    end

  end

  context "new" do

    it "gets new page when there are no institutions" do
      get :new
      expect(response).to be_success
    end

    it "gets new page when there is one institution" do
      user.institutions.make
      get :new
      expect(response).to be_success
    end

    it "gets new page when there are many institutions" do
      2.times { user.institutions.make }
      get :new
      expect(response).to be_success
    end

  end

end
