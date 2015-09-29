require 'spec_helper'
require 'policy_spec_helper'

describe LaboratoriesController do

  let!(:institution) {Institution.make}
  let!(:user)        {institution.user}

  let!(:institution2) { Institution.make }
  let!(:laboratory2)  { institution2.laboratories.make }

  before(:each) {sign_in user}

  context "index" do

    let!(:laboratory) { institution.laboratories.make }
    let!(:other_laboratory) { Laboratory.make }

    it "should get accessible laboratories in index" do
      get :index

      expect(response).to be_success
      expect(assigns(:laboratories)).to contain_exactly(laboratory)
      expect(assigns(:labs_to_edit)).to contain_exactly(laboratory.id)
      expect(assigns(:can_create)).to be_truthy
    end

    it "should filter by institution if requested" do
      grant nil, user, "laboratory?institution=#{institution2.id}", [READ_LABORATORY]

      get :index, institution: institution2.id

      expect(response).to be_success
      expect(assigns(:laboratories)).to contain_exactly(laboratory2)
      expect(assigns(:labs_to_edit)).to be_empty
    end

  end

  context "new" do

    it "should get new page" do
      get :new
      expect(response).to be_success
    end

  end

  context "create" do

    it "should create new laboratory" do
      expect {
        post :create, laboratory: Laboratory.plan(institution: institution)
      }.to change(institution.laboratories, :count).by(1)
      expect(response).to be_redirect
    end

    it "should not create laboratory for another institution" do
      expect {
        post :create, laboratory: Laboratory.plan(institution: institution2)
      }.to change(institution.laboratories, :count).by(0)
      expect(response).to be_forbidden
    end

  end

  context "edit" do

    let!(:laboratory) { institution.laboratories.make }
    let!(:other_laboratory) { Laboratory.make }

    it "should edit laboratory" do
      get :edit, id: laboratory.id
      expect(response).to be_success
    end

    it "should not edit laboratory if not allowed" do
      get :edit, id: laboratory2.id
      expect(response).to be_forbidden
    end

  end

  context "update" do

    let!(:laboratory) { institution.laboratories.make }

    it "should update laboratory" do
      expect(Location).to receive(:details) { [Location.new(lat: 10, lng: -42)] }
      patch :update, id: laboratory.id, laboratory: { name: "newname" }
      expect(laboratory.reload.name).to eq("newname")
      expect(response).to be_redirect
    end

    it "should not update laboratory for another institution" do
      patch :update, id: laboratory2.id, laboratory: { name: "newname" }
      expect(laboratory2.reload.name).to_not eq("newname")
      expect(response).to be_forbidden
    end

  end

  context "destroy" do

    let!(:laboratory) { institution.laboratories.make }

    it "should destroy a laboratory" do
      expect {
        delete :destroy, id: laboratory.id
      }.to change(institution.laboratories, :count).by(-1)
      expect(response).to be_redirect
    end

    it "should not destroy laboratory for another institution" do
      expect {
        delete :destroy, id: laboratory2.id
      }.to change(institution2.laboratories, :count).by(0)
      expect(response).to be_forbidden
    end

  end

end
