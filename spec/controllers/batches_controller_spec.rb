require 'spec_helper'
require 'policy_spec_helper'

RSpec.describe BatchesController, type: :controller do
  let!(:institution)   { Institution.make }
  let!(:user)          { institution.user }
  before(:each)        { sign_in user }
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

    it "should list batches if can read" do
      institution.batches.make
      get :index
      expect(assigns(:batches).count).to eq(1)
    end

    it "should not list batches if can not read" do
      institution.batches.make
      sign_in other_user
      get :index
      expect(assigns(:batches).count).to eq(0)
    end

    it "can create if admin" do
      get :index
      expect(assigns(:can_create)).to be_truthy
    end

    it "can create if allowed" do
      grant user, other_user, institution, CREATE_INSTITUTION_BATCH
      sign_in other_user
      get :index
      expect(assigns(:can_create)).to be_truthy
    end

    it "can not create if not allowed" do
      sign_in other_user
      get :index
      expect(assigns(:can_create)).to be_falsy
    end

    it "should filter by Isolate Name" do
      institution.batches.make batch_number: '123', isolate_name: 'ABC.42'
      institution.batches.make batch_number: '456', isolate_name: 'DEF.24'
      institution.batches.make batch_number: '789', isolate_name: 'GHI.42'

      get :index, isolate_name: '42'
      expect(response).to be_success
      expect(assigns(:batches).count).to eq(2)
    end

    it "should filter by Batch Number" do
      institution.batches.make batch_number: '7788'
      institution.batches.make batch_number: '8877'
      institution.batches.make batch_number: '0123'

      get :index, batch_number: '88'
      expect(response).to be_success
      expect(assigns(:batches).count).to eq(2)
    end

    # TODO:
    # it "should filter by Sample ID" do
    #   institution.batches.make batch_number: '7788'
    #   institution.batches.make batch_number: '8877'
    #   institution.batches.make batch_number: '0123'

    #   get :index, batch_number: '88'
    #   expect(response).to be_success
    #   expect(assigns(:batches).count).to eq(2)
    # end

    # TODO: navigation_context site
    # it "should filter based con navigation_context site" do
    #   site1 = institution.sites.make
    #   site11 = Site.make :child, parent: site1
    #   site2 = institution.sites.make

    #   patient1 = institution.patients.make
    #   patient2 = institution.patients.make

    #   patient1.encounters.make site: site11
    #   patient2.encounters.make site: site2

    #   get :index, context: site1.uuid

    #   expect(response).to be_success
    #   expect(assigns(:patients).to_a).to eq([patient1])
    # end
  end

  context "new" do
    it "should be accessible be institution owner" do
      get :new
      expect(response).to be_success
    end

    it "should be allowed it can create" do
      grant user, other_user, institution, CREATE_INSTITUTION_BATCH
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
    let(:batch_form_plan) {
      { batch_number: '123',
        isolate_name: 'ABC.42',
        date_produced: '08/08/2018',
        lab_technician: 'Tec.Foo',
        specimen_role: 'Q - Control specimen',
        inactivation_method: 'Formaldehyde',
        volume: '100',
        samples_quantity: '1'
      }
    }

    def build_batch_form_plan(options)
      batch_form_plan.dup.merge! options
    end

    it "should create new batch in context institution" do
      expect {
        post :create, batch: batch_form_plan
      }.to change(institution.batches, :count).by(1)

      expect(response).to redirect_to batches_path
    end

    it "should save fields" do
      post :create, batch: batch_form_plan
      batch = institution.batches.last

      expect(batch.batch_number).to eq(batch_form_plan[:batch_number])
      expect(batch.isolate_name).to eq(batch_form_plan[:isolate_name])
      expect(batch.date_produced).to eq(batch_form_plan[:date_produced])
      expect(batch.lab_technician).to eq(batch_form_plan[:lab_technician])
      expect(batch.specimen_role).to eq(batch_form_plan[:specimen_role])
      expect(batch.inactivation_method).to eq(batch_form_plan[:inactivation_method])
      expect(batch.volume).to eq(batch_form_plan[:volume])

      # samples created (see samples_quantity)
      expect(batch.samples.count).to eq(1)

      expect(batch.core_fields['batch_number']).to eq(batch_form_plan[:batch_number])
      expect(batch.core_fields['isolate_name']).to eq(batch_form_plan[:isolate_name])
      expect(batch.core_fields['date_produced']).to eq(batch_form_plan[:date_produced])
      expect(batch.core_fields['lab_technician']).to eq(batch_form_plan[:lab_technician])
      expect(batch.core_fields['specimen_role']).to eq(batch_form_plan[:specimen_role])
      expect(batch.core_fields['inactivation_method']).to eq(batch_form_plan[:inactivation_method])
      expect(batch.core_fields['volume']).to eq(batch_form_plan[:volume])
    end

    it "should create new batch in context institution if allowed" do
      grant user, other_user, institution, CREATE_INSTITUTION_BATCH
      sign_in other_user

      expect {
        post :create, batch: batch_form_plan
      }.to change(institution.batches, :count).by(1)
    end

    it "should not create new batch in context institution if not allowed" do
      sign_in other_user

      expect {
        post :create, batch: batch_form_plan
      }.to change(institution.batches, :count).by(0)

      expect(response).to be_forbidden
    end

    it "should require date_produced" do
      expect {
        post :create, batch: build_batch_form_plan(date_produced: '')
      }.to change(institution.samples, :count).by(0)

      expect(assigns(:batch_form).errors).to have_key(:date_produced)
      expect(response).to render_template("batches/new")
    end

    it "should validate date_produced" do
      expect {
        post :create, batch: build_batch_form_plan(date_produced: '31/31/3100')
      }.to change(institution.batches, :count).by(0)

      expect(assigns(:batch_form).errors).to have_key(:date_produced)
      expect(response).to render_template("batches/new")
    end

    it "should require lab_technician" do
      expect {
        post :create, batch: build_batch_form_plan(lab_technician: '')
      }.to change(institution.batches, :count).by(0)

      expect(assigns(:batch_form).errors).to have_key(:lab_technician)
      expect(response).to render_template("batches/new")
    end

    it "should require inactivation_method" do
      expect {
        post :create, batch: build_batch_form_plan(inactivation_method: '')
      }.to change(institution.batches, :count).by(0)

      expect(assigns(:batch_form).errors).to have_key(:inactivation_method)
      expect(response).to render_template("batches/new")
    end

    it "should require volume" do
      expect {
        post :create, batch: build_batch_form_plan(volume: '')
      }.to change(institution.batches, :count).by(0)

      expect(assigns(:batch_form).errors).to have_key(:volume)
      expect(response).to render_template("batches/new")
    end

    it "should not require specimen_role" do
      expect {
        post :create, batch: build_batch_form_plan(specimen_role: '')
      }.to change(institution.batches, :count).by(1)

      batch = institution.batches.last
      expect(batch.specimen_role).to be_nil
      expect(response).to redirect_to batches_path
    end

    # TODO: navigation_context site
    # it "should use navigation_context as patient site" do
    #   site = institution.sites.make
    #   expect {
    #     post :create, context: site.uuid, patient: patient_form_plan
    #   }.to change(institution.patients, :count).by(1)

    #   expect(Patient.last.site).to eq(site)

    #   expect(response).to be_redirect
    # end
  end

  context "edit" do
    let!(:batch) { institution.batches.make(
      batch_number: '123',
      isolate_name: 'ABC.42',
      date_produced: Time.strptime('01/01/2018', I18n.t('date.input_format.pattern')),
      lab_technician: 'Tec.Foo',
      specimen_role: 'Q - Control specimen',
      inactivation_method: 'Formaldehyde',
      volume: 100
    )}

    it "should be accessible by institution owner" do
      get :edit, id: batch.id
      expect(response).to be_success
      expect(assigns(:can_delete)).to be_truthy
    end

    it "should be accessible if can edit" do
      grant user, other_user, Batch, UPDATE_BATCH
      sign_in other_user

      get :edit, id: batch.id
      expect(response).to be_success
      expect(assigns(:can_delete)).to be_falsy
    end

    it "should not be accessible if can not edit" do
      sign_in other_user

      get :edit, id: batch.id
      expect(response).to be_forbidden
    end

    it "should allow to delete if can delete" do
      grant user, other_user, Batch, UPDATE_BATCH
      grant user, other_user, Batch, DELETE_BATCH
      sign_in other_user

      get :edit, id: batch.id
      expect(response).to be_success
      expect(assigns(:can_delete)).to be_truthy
    end
  end

  context "update" do
    let!(:batch) { institution.batches.make(
      batch_number: '123',
      isolate_name: 'ABC.42',
      date_produced: Time.strptime('08/08/2021', I18n.t('date.input_format.pattern')),
      lab_technician: 'Tec.Foo',
      specimen_role: 'Q - Control specimen',
      inactivation_method: 'Formaldehyde',
      volume: 100
    )}

    it "should update existing batch" do
      post :update, id: batch.id, batch: {
        isolate_name: 'ABC.42',
        date_produced: '09/09/2021',
        lab_technician: 'TecFoo',
        specimen_role: 'P - Patient',
        inactivation_method: 'Heat',
        volume: '200'
      }
      expect(response).to be_redirect

      batch.reload
      expect(batch.isolate_name).to eq('ABC.42')
      expect(batch.date_produced).to eq('09/09/2021')
      expect(batch.lab_technician).to eq('TecFoo')
      expect(batch.specimen_role).to eq('P - Patient')
      expect(batch.inactivation_method).to eq('Heat')
      expect(batch.volume).to eq('200')
    end

    it "should require date_produced" do
      post :update, id: batch.id, batch: { date_produced: '' }
      expect(assigns(:batch_form).errors).to have_key(:date_produced)
      expect(response).to render_template("batches/edit")
    end

    it "should update existing batch if allowed" do
      grant user, other_user, Batch, UPDATE_BATCH

      sign_in other_user
      post :update, id: batch.id, batch: {
        isolate_name: 'ABC.42',
        date_produced: '09/09/2021',
        lab_technician: 'TecFoo',
        specimen_role: 'P - Patient',
        inactivation_method: 'Heat',
        volume: '200'
      }
      expect(response).to be_redirect

      batch.reload
      expect(batch.isolate_name).to eq('ABC.42')
      expect(batch.date_produced).to eq('09/09/2021')
      expect(batch.lab_technician).to eq('TecFoo')
      expect(batch.specimen_role).to eq('P - Patient')
      expect(batch.inactivation_method).to eq('Heat')
      expect(batch.volume).to eq('200')
    end

    it "should not update existing batch if not allowed" do
      sign_in other_user
      post :update, id: batch.id, sample: { date_produced: '09/09/2021' }
      expect(response).to be_forbidden

      batch.reload
      expect(batch.date_produced).to_not eq('09/09/2021')
    end
  end

  context "destroy" do
    let!(:batch) { institution.batches.make(
      batch_number: '123',
      isolate_name: 'ABC.42',
      date_produced: Time.strptime('08/08/2021', I18n.t('date.input_format.pattern')),
      lab_technician: 'Tec.Foo',
      specimen_role: 'Q - Control specimen',
      inactivation_method: 'Formaldehyde',
      volume: 100
    )}


    it "should be able to soft delete a batch" do
      expect {
        delete :destroy, id: batch.id
      }.to change(institution.batches, :count).by(-1)

      batch.reload
      expect(batch.deleted_at).to_not be_nil

      expect(response).to be_redirect
    end

    it "should be able to delete if can delete" do
      grant user, other_user, Batch, DELETE_BATCH
      sign_in other_user

      expect {
        delete :destroy, id: batch.id
      }.to change(institution.batches, :count).by(-1)

      batch.reload
      expect(batch.deleted_at).to_not be_nil
    end

    it "should not able to delete if can not delete" do
      sign_in other_user

      expect {
        delete :destroy, id: batch.id
      }.to change(institution.batches, :count).by(0)

      expect(response).to be_forbidden
    end
  end

  # TODO: search institution/site
  # context "search" do
  #   it "should search in entire institution" do
  #     site1 = institution.sites.make
  #     site2 = institution.sites.make
  #     other_institution = Institution.make user: user

  #     patient1 = institution.patients.make name: 'john doe', site: site1
  #     patient2 = institution.patients.make name: 'john foo', site: site2
  #     other_institution.patients.make name: 'john alone'

  #     get :search, q: 'john', context: site1.uuid

  #     json_response = JSON.parse(response.body)
  #     expect(json_response.map { |p| p["id"] }).to match([patient1.id, patient2.id])
  #   end
  # end
end
