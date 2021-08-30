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

    it "should filter by Sample ID" do
      batch = institution.batches.make batch_number: '7788'
      batch.samples.make sample_identifiers: [SampleIdentifier.make(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e88')]

      get :index, sample_id: '88'
      expect(response).to be_success
      expect(assigns(:batches).count).to eq(1)
    end
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

    let!(:batch) { institution.batches.make(
      batch_number: '1234',
      isolate_name: 'ABC.424',
      date_produced: Time.strptime('08/08/2021', I18n.t('date.input_format.pattern')),
      lab_technician: 'Tec.Foo',
      specimen_role: 'Q - Control specimen',
      inactivation_method: 'Formaldehyde',
      volume: 100
    )}

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
      }.to change(institution.batches, :count).by(0)

      expect(assigns(:batch_form).errors).to have_key(:date_produced)
      expect(response).to render_template("batches/new")
    end

    it "should require batch_number" do

      expect {
        post :create, batch: build_batch_form_plan(batch_number: '')
      }.to change(institution.batches, :count).by(0)

      expect(assigns(:batch_form).errors).to have_key(:batch_number)
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

    it "should validate isolate_name and batch_number combination" do

      puts "***********DEBUGGER***********"
      puts batch.id
      puts "***********DEBUGGER***********"
      puts batch.batch_number
      puts "***********DEBUGGER***********"
      puts batch.isolate_name


      batch_1 = build_batch_form_plan(batch_number: '1234', isolate_name: 'ABC.424')
      puts "***********DEBUGGER BATCH_1***********"
      puts batch_1[:id] != batch.id
      puts "***********DEBUGGER BATCH_1***********"
      puts batch_1[:batch_number] == batch.batch_number
      puts "***********DEBUGGER BATCH_1***********"
      puts batch_1[:isolate_name] == batch.isolate_name

      expect {
        post :create, batch: build_batch_form_plan(batch_number: '1234', isolate_name: 'ABC.424')
      }.to change(institution.batches, :count).by(0)

      expect(response).to render_template("batches/new")
    end

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
      post :update, id: batch.id, batch: { date_produced: '09/09/2021' }
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

  context "bulk_destroy" do
    let!(:batch1) { institution.batches.make(
      batch_number: '123',
      isolate_name: 'ABC.42',
      date_produced: Time.strptime('08/08/2021', I18n.t('date.input_format.pattern')),
      lab_technician: 'Tec.Foo',
      specimen_role: 'Q - Control specimen',
      inactivation_method: 'Formaldehyde',
      volume: 100
    )}

    let!(:batch2) { institution.batches.make(
      batch_number: '456',
      isolate_name: 'DEF.24',
      date_produced: Time.strptime('09/09/2020', I18n.t('date.input_format.pattern')),
      lab_technician: 'Tec.Foo',
      specimen_role: 'Q - Control specimen',
      inactivation_method: 'Formaldehyde',
      volume: 200
    )}

    let!(:institution2)   { Institution.make }
    let!(:batch3) { institution2.batches.make(
      batch_number: '789',
      isolate_name: 'GHI.4224',
      date_produced: Time.strptime('07/07/2019', I18n.t('date.input_format.pattern')),
      lab_technician: 'Tec.Foo',
      specimen_role: 'Q - Control specimen',
      inactivation_method: 'Formaldehyde',
      volume: 300
    )}

    it "should be able to bulk destroy batches" do

      expect {
        post :bulk_destroy, batch_ids: [batch1.id, batch2.id]
      }.to change(institution.batches, :count).by(-2)

      batch1.reload
      expect(batch1.deleted_at).to_not be_nil
      batch2.reload
      expect(batch2.deleted_at).to_not be_nil

      expect(response).to be_redirect
    end

    it "should be able to bulk destroy if can DELETE" do
      grant user, other_user, Batch, DELETE_BATCH
      sign_in other_user

      expect {
        post :bulk_destroy, batch_ids: [batch1.id, batch2.id]
      }.to change(institution.batches, :count).by(-2)

      batch1.reload
      expect(batch1.deleted_at).to_not be_nil
      batch2.reload
      expect(batch2.deleted_at).to_not be_nil
    end

    it "should not able to bulk destroy if can not DELETE" do
      sign_in other_user

      expect {
        post :bulk_destroy, batch_ids: [batch1.id, batch2.id]
      }.to change(institution.batches, :count).by(0)

      expect(response).to be_forbidden
    end

    it "should not able to bulk destroy if can not DELETE all batches" do
      expect {
        post :bulk_destroy, batch_ids: [batch1.id, batch2.id, batch3.id]
      }.to change(institution.batches, :count).by(0)

      expect(response).to be_forbidden
    end
  end
end
