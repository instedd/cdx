require 'spec_helper'

RSpec.describe PatientsController, type: :controller do
  let!(:institution) {Institution.make}
  let!(:user)        {institution.user}
  before(:each) {sign_in user}
  let(:default_params) { {context: institution.uuid} }

  context "index" do
    it "should be accessible by institution owner" do
      get :index
      expect(response).to be_success
    end
  end

  context "new" do
    it "should be accessible be institution owner" do
      get :new
      expect(response).to be_success
    end
  end

  context "create" do
    it "should create new patient in context institution" do
      expect {
        post :create, patient: { name: 'Lorem', dob_text: '1/1/2000' }
      }.to change(institution.patients, :count).by(1)

      expect(response).to be_redirect
    end

    it "should require name" do
      expect {
        post :create, patient: { name: '', dob_text: '1/1/2000' }
      }.to change(institution.patients, :count).by(0)

      expect(assigns(:patient).errors).to have_key(:name)
      expect(response).to render_template("patients/new")
    end

    it "should require dob" do
      expect {
        post :create, patient: { name: 'Jerry', dob_text: '' }
      }.to change(institution.patients, :count).by(0)

      expect(assigns(:patient).errors).to have_key(:dob_text)
      expect(response).to render_template("patients/new")
    end

    it "should validate dob" do
      expect {
        post :create, patient: { name: 'Jerry', dob_text: '14/14/2000' }
      }.to change(institution.patients, :count).by(0)

      expect(assigns(:patient).errors).to have_key(:dob_text)
      expect(response).to render_template("patients/new")
    end
  end

  context "edit" do
    it "should be accessible be institution owner" do
      patient = institution.patients.make
      get :edit, id: patient.id
      expect(response).to be_success
    end
  end

  context "update" do
    it "should update existing patient" do
      patient = institution.patients.make
      post :update, id: patient.id, patient: { name: 'Lorem', dob_text: '1/1/2000' }
      expect(response).to be_redirect

      patient.reload
      expect(patient.name).to eq("Lorem")
      expect(Time.parse(patient.dob)).to eq(Time.parse("2000-01-01"))
    end

    it "should require name" do
      patient = institution.patients.make
      post :update, id: patient.id, patient: { name: '', dob_text: '1/1/2000' }
      expect(assigns(:patient).errors).to have_key(:name)
      expect(response).to render_template("patients/edit")
    end
  end

  context "destroy" do
    it "should be able to soft delete a patient" do
      patient = institution.patients.make

      expect {
        delete :destroy, id: patient.id
      }.to change(institution.patients, :count).by(-1)

      patient.reload
      expect(patient.deleted_at).to_not be_nil

      expect(response).to be_redirect
    end
  end
end
