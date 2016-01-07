require 'spec_helper'
require 'policy_spec_helper'

RSpec.describe PatientsController, type: :controller do
  let!(:institution) {Institution.make}
  let!(:user)        {institution.user}
  before(:each) {sign_in user}
  let(:default_params) { {context: institution.uuid} }

  let!(:other_user) { Institution.make.user }
  before(:each) {
    grant user, other_user, institution, READ_INSTITUTION
  }

  context "index" do
    it "should be accessible by institution owner" do
      get :index
      expect(response).to be_success
    end

    it "should list patients if can read" do
      institution.patients.make
      get :index
      expect(assigns(:patients).count).to eq(1)
    end

    it "should not list patients if can not read" do
      institution.patients.make
      sign_in other_user
      get :index
      expect(assigns(:patients).count).to eq(0)
    end

    it "can create if admin" do
      get :index
      expect(assigns(:can_create)).to be_truthy
    end

    it "can create if allowed" do
      grant user, other_user, institution, CREATE_INSTITUTION_PATIENT
      sign_in other_user
      get :index
      expect(assigns(:can_create)).to be_truthy
    end

    it "can not create if not allowed" do
      sign_in other_user
      get :index
      expect(assigns(:can_create)).to be_falsy
    end
  end

  context "show" do
    let!(:patient) { institution.patients.make }

    it "should be accessible be institution owner" do
      get :show, id: patient.id
      expect(response).to be_success
      expect(assigns(:can_edit)).to be_truthy
    end

    it "should not be accessible if can not read" do
      sign_in other_user
      get :show, id: patient.id
      expect(response).to be_forbidden
    end

    it "should be accessible if can read" do
      grant user, other_user, Patient, READ_PATIENT
      sign_in other_user
      get :show, id: patient.id
      expect(response).to be_success
      expect(assigns(:can_edit)).to be_falsy
    end

    it "should allow to edit if can update" do
      grant user, other_user, Patient, READ_PATIENT
      grant user, other_user, Patient, UPDATE_PATIENT
      sign_in other_user
      get :show, id: patient.id
      expect(response).to be_success
      expect(assigns(:can_edit)).to be_truthy
    end
  end

  context "new" do
    it "should be accessible be institution owner" do
      get :new
      expect(response).to be_success
    end

    it "should be allowed it can create" do
      grant user, other_user, institution, CREATE_INSTITUTION_PATIENT
      sign_in other_user
      get :new
      expect(response).to be_success
    end

    it "should not be allowed it can not create" do
      sign_in other_user
      get :new
      expect(response).to be_forbidden
    end
  end

  context "create" do
    it "should create new patient in context institution" do
      expect {
        post :create, patient: { name: 'Lorem', gender: 'female', dob_text: '1/1/2000' }
      }.to change(institution.patients, :count).by(1)

      expect(response).to be_redirect
    end

    it "should save fields" do
      post :create, patient: { name: 'Lorem', gender: 'female', dob_text: '1/1/2000' }
      patient = institution.patients.last

      expect(patient.name).to eq('Lorem')
      expect(patient.gender).to eq('female')
      expect(Time.parse(patient.dob)).to eq(Time.parse("2000-01-01"))

      expect(patient.plain_sensitive_data['name']).to eq('Lorem')
      expect(patient.core_fields['gender']).to eq('female')
      expect(Time.parse(patient.plain_sensitive_data['dob'])).to eq(Time.parse("2000-01-01"))
    end

    it "should create new patient in context institution if allowed" do
      grant user, other_user, institution, CREATE_INSTITUTION_PATIENT
      sign_in other_user

      expect {
        post :create, patient: { name: 'Lorem', gender: 'female', dob_text: '1/1/2000' }
      }.to change(institution.patients, :count).by(1)
    end

    it "should not create new patient in context institution if not allowed" do
      sign_in other_user

      expect {
        post :create, patient: { name: 'Lorem', dob_text: '1/1/2000' }
      }.to change(institution.patients, :count).by(0)

      expect(response).to be_forbidden
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

    it "should validate gender" do
      expect {
        post :create, patient: { name: '', gender: '' }
      }.to change(institution.patients, :count).by(0)

      expect(assigns(:patient).errors).to have_key(:gender)
      expect(response).to render_template("patients/new")
    end
  end

  context "edit" do
    let!(:patient) { institution.patients.make }

    it "should be accessible by institution owner" do
      get :edit, id: patient.id
      expect(response).to be_success
      expect(assigns(:can_delete)).to be_truthy
    end

    it "should be accessible if can edit" do
      grant user, other_user, Patient, UPDATE_PATIENT
      sign_in other_user

      get :edit, id: patient.id
      expect(response).to be_success
      expect(assigns(:can_delete)).to be_falsy
    end

    it "should not be accessible if can not edit" do
      sign_in other_user

      get :edit, id: patient.id
      expect(response).to be_forbidden
    end

    it "should allow to delete if can delete" do
      grant user, other_user, Patient, UPDATE_PATIENT
      grant user, other_user, Patient, DELETE_PATIENT
      sign_in other_user

      get :edit, id: patient.id
      expect(response).to be_success
      expect(assigns(:can_delete)).to be_truthy
    end
  end

  context "update" do
    let(:patient) { institution.patients.make }

    it "should update existing patient" do
      post :update, id: patient.id, patient: { name: 'Lorem', gender: 'female', dob_text: '1/1/2000' }
      expect(response).to be_redirect

      patient.reload
      expect(patient.name).to eq("Lorem")
      expect(patient.gender).to eq("female")
      expect(Time.parse(patient.dob)).to eq(Time.parse("2000-01-01"))
    end

    it "should require name" do
      post :update, id: patient.id, patient: { name: '', dob_text: '1/1/2000' }
      expect(assigns(:patient).errors).to have_key(:name)
      expect(response).to render_template("patients/edit")
    end

    it "should update existing patient if allowed" do
      grant user, other_user, Patient, UPDATE_PATIENT

      sign_in other_user
      post :update, id: patient.id, patient: { name: 'Lorem', gender: 'female', dob_text: '1/1/2000' }
      expect(response).to be_redirect

      patient.reload
      expect(patient.name).to eq("Lorem")
      expect(patient.gender).to eq("female")
      expect(Time.parse(patient.dob)).to eq(Time.parse("2000-01-01"))
    end

    it "should not update existing patient if allowed" do
      sign_in other_user
      post :update, id: patient.id, patient: { name: 'Lorem', dob_text: '1/1/2000' }
      expect(response).to be_forbidden

      patient.reload
      expect(patient.name).to_not eq("Lorem")
    end
  end

  context "destroy" do
    let!(:patient) { institution.patients.make }

    it "should be able to soft delete a patient" do
      expect {
        delete :destroy, id: patient.id
      }.to change(institution.patients, :count).by(-1)

      patient.reload
      expect(patient.deleted_at).to_not be_nil

      expect(response).to be_redirect
    end

    it "should be able to delete if can delete" do
      grant user, other_user, Patient, DELETE_PATIENT
      sign_in other_user

      expect {
        delete :destroy, id: patient.id
      }.to change(institution.patients, :count).by(-1)

      patient.reload
      expect(patient.deleted_at).to_not be_nil
    end

    it "should not able to delete if can delete" do
      sign_in other_user

      expect {
        delete :destroy, id: patient.id
      }.to change(institution.patients, :count).by(0)

      expect(response).to be_forbidden
    end
  end
end
