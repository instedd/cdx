require 'spec_helper'
require 'policy_spec_helper'

RSpec.describe SamplesController, type: :controller do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user

    @other_user = Institution.make!.user
  end

  let(:default_params) { {context: institution.uuid} }
  let(:loinc_code)     { LoincCode.make! }

  before(:each) do
    grant user, other_user, institution, READ_INSTITUTION
    sign_in user

    # WickedPDF will try to request Google Fonts
    stub_request(:get, %r{^https://fonts\.googleapis\.com/css})
      .with(:query => hash_including("family"))
      .to_return(:status => 200, :body => "", :headers => {})
  end

  context "index" do
    it "should be accessible by institution owner" do
      get :index
      expect(response).to be_success
    end

    it "should list samples if can read" do
      Sample.make! institution: institution
      get :index
      expect(assigns(:samples).count).to eq(1)
    end

    it "should not list samples if can not read" do
      Sample.make! institution: institution
      sign_in other_user
      get :index
      expect(assigns(:samples).count).to eq(0)
    end

    it "can create if admin" do
      get :index
      expect(assigns(:can_create)).to be_truthy
    end

    it "can create if allowed" do
      grant user, other_user, institution, CREATE_INSTITUTION_SAMPLE
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
      Sample.make! institution: institution, isolate_name: 'ABC.42'
      Sample.make! institution: institution, isolate_name: 'DEF.24'
      Sample.make! institution: institution, isolate_name: 'GHI.42'

      get :index, params: { isolate_name: '42' }
      expect(response).to be_success
      expect(assigns(:samples).count).to eq(2)
    end

    it "should filter by Sample ID" do
      Sample.make! institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e88')]
      Sample.make! institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: '89101112-8ce1-a0c8-ac1b-58bed3633e88')]
      Sample.make! institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: '13141516-8ce1-a0c8-ac1b-58bed3633e00')]

      get :index, params: { sample_id: '88' }
      expect(response).to be_success
      expect(assigns(:samples).count).to eq(2)
    end

    it "excludes samples in transit" do
      sample = Sample.make(institution: institution)
      sample.detach_from_context

      get :index
      expect(assigns(:samples)).to be_empty
    end
  end

  context "edit_or_show" do
    let!(:sample) do
      Sample.make! institution: institution, sample_identifiers: [
        SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e88'),
      ]
    end

    it "redirects to edit when user has UPDATE_SAMPLE permission" do
      get :edit_or_show, params: { id: sample.id }
      expect(response).to redirect_to(edit_sample_path(sample))
    end

    it "redirects to show when user doesn't have UPDATE_SAMPLE permission" do
      sign_in other_user

      get :edit_or_show, params: { id: sample.id }
      expect(response).to redirect_to(sample_path(sample))
    end
  end

  context "show" do
    let!(:sample) do
      Sample.make! institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e88')]
    end

    it "should be accessible to institution owner" do
      get :show, params: { id: sample.id }
      expect(response).to be_success
    end

    it "shouldn't be accessible to anybody" do
      sign_in other_user

      get :show, params: { id: sample.id }
      expect(response).to be_forbidden
    end

    it "shows old_batch_number" do
      sample.update(old_batch_number: "1234567")

      get :show, params: { id: sample.id }

      expect(response.body).to include(sample.old_batch_number)
    end

    context "blinded attributes" do
      let(:batch) do
        Batch.make!(
          institution: institution,
          batch_number: "B.CV19.123",
        )
      end

      let(:sample) do
        Sample.make!(
          institution: institution,
          batch: batch,
          virus_lineage: "CV.19.B.1.1.XYZ",
          concentration_number: 5,
          concentration_exponent: 8,
          replicate: 2,
          date_produced: Date.today.to_s,
          sample_identifiers: [SampleIdentifier.make],
        )
      end

      it "blinds values when box is blinded (LOD)" do
        Box.make! institution: institution, samples: [sample], purpose: "LOD", blinded: true

        get :show, params: { id: sample.to_param }
        expect(response).to have_http_status(:ok)

        expect(response.body).to include("Blinded value")
        expect(response.body).to include(batch.batch_number)
        assert_select "input[name='sample[concentration_number]']", count: 0
        assert_select "input[name='sample[concentration_exponent]']", count: 0
        assert_select "input[name='sample[replicate]']", count: 0
        assert_select "input[name='sample[virus_lineage]'][value='CV.19.B.1.1.XYZ']"
      end

      it "blinds values when box is blinded (Variants)" do
        Box.make! institution: institution, samples: [sample], purpose: "Variants", blinded: true

        get :show, params: { id: sample.to_param }
        expect(response).to have_http_status(:ok)

        expect(response.body).to include("Blinded value")
        expect(response.body).to_not include(batch.batch_number)
        assert_select "input[name='sample[concentration_number]'][value=5]"
        assert_select "input[name='sample[concentration_exponent]'][value=8]"
        assert_select "input[name='sample[replicate]'][value=2]"
        assert_select "input[name='sample[virus_lineage]']", count: 0
      end

      it "blinds values when box is blinded (Challenge)" do
        Box.make! institution: institution, samples: [sample], purpose: "Challenge", blinded: true

        get :show, params: { id: sample.to_param }
        expect(response).to have_http_status(:ok)

        expect(response.body).to include("Blinded value")
        expect(response.body).to_not include(batch.batch_number)
        assert_select "input[name='sample[concentration_number]']", count: 0
        assert_select "input[name='sample[concentration_exponent]']", count: 0
        assert_select "input[name='sample[replicate]']", count: 0
        assert_select "input[name='sample[virus_lineage]']", count: 0
      end
    end
  end

  context "new" do
    it "should be accessible be institution owner" do
      get :new
      expect(response).to be_success
    end

    it "should be allowed it can create" do
      grant user, other_user, institution, CREATE_INSTITUTION_SAMPLE
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
    let(:sample_form_plan) {
      { isolate_name: 'ABC.42', date_produced: '08/08/2018' }
    }

    def build_sample_form_plan(options)
      sample_form_plan.dup.merge! options
    end

    it "should create new sample in context institution" do
      expect {
        # sets session[:creating_sample_uuid] (see implementation)
        get :new
        # use session[:creating_sample_uuid]
        post :create, params: { sample: sample_form_plan }
      }.to change(institution.samples, :count).by(1)

      expect(response).to redirect_to samples_path
    end

    it "should save fields" do
      get :new
      post :create, params: { sample: sample_form_plan }
      sample = institution.samples.last

      expect(sample.isolate_name).to eq(sample_form_plan[:isolate_name])
      expect(sample.date_produced).to eq(sample_form_plan[:date_produced])

      expect(sample.core_fields['date_produced']).to eq(sample_form_plan[:date_produced])
    end

    it "should create new sample in context institution if allowed" do
      grant user, other_user, institution, CREATE_INSTITUTION_SAMPLE
      sign_in other_user

      expect {
        get :new
        post :create, params: { sample: sample_form_plan }
      }.to change(institution.samples, :count).by(1)
    end

    it "should not create new sample in context institution if not allowed" do
      sign_in other_user

      expect {
        get :new
        post :create, params: { sample: sample_form_plan }
      }.to change(institution.samples, :count).by(0)

      expect(response).to be_forbidden
    end

    it "should require date_produced" do
      expect {
        get :new
        post :create, params: { sample: build_sample_form_plan(date_produced: '') }
      }.to change(institution.samples, :count).by(0)

      expect(assigns(:sample_form).errors).to have_key(:date_produced)
      expect(response).to render_template("samples/new")
    end

    it "should validate date_produced" do
      expect {
        get :new
        post :create, params: { sample: build_sample_form_plan(date_produced: '31/31/3100') }
      }.to change(institution.samples, :count).by(0)

      expect(assigns(:sample_form).errors).to have_key(:date_produced)
      expect(response).to render_template("samples/new")
    end

    it "should not require isolate_name" do
      expect {
        get :new
        post :create, params: { sample: build_sample_form_plan(isolate_name: '') }
      }.to change(institution.samples, :count).by(1)

      sample = institution.samples.first
      expect(sample.isolate_name).to be_nil
      expect(sample.core_fields).to_not have_key('isolate_name')
    end

    it "should not require lab_technician" do
      expect {
        get :new
        post :create, params: { sample: build_sample_form_plan(lab_technician: '') }
      }.to change(institution.samples, :count).by(1)

      sample = institution.samples.first
      expect(sample.lab_technician).to be_nil
      expect(sample.core_fields).to_not have_key('lab_technician')
    end

    it "should not require specimen_role" do
      expect {
        get :new
        post :create, params: { sample: build_sample_form_plan(specimen_role: '') }
      }.to change(institution.samples, :count).by(1)

      sample = institution.samples.first
      expect(sample.specimen_role).to be_nil
      expect(sample.core_fields).to_not have_key('specimen_role')
    end

    it "should not require inactivation_method" do
      expect {
        get :new
        post :create, params: { sample: build_sample_form_plan(inactivation_method: '') }
      }.to change(institution.samples, :count).by(1)

      sample = institution.samples.first
      expect(sample.inactivation_method).to be_nil
      expect(sample.core_fields).to_not have_key('inactivation_method')
    end

    it "should not require volume" do
      expect {
        get :new
        post :create, params: { sample: build_sample_form_plan(volume: '') }
      }.to change(institution.samples, :count).by(1)

      sample = institution.samples.first
      expect(sample.volume).to be_nil
      expect(sample.core_fields).to_not have_key('volume')
    end

    it "creates with optional params" do
      expect do
        get :new
        post :create, params: { sample: build_sample_form_plan(
          virus_lineage: "B.1.1.529",
          concentration_number: 2,
          concentration_exponent: 8,
          replicate: 12,
          media: "Other",
        ) }
      end.to change(institution.samples, :count).by(1)

      sample = institution.samples.first
      expect(sample.virus_lineage).to eq("B.1.1.529")
      expect(sample.concentration_number).to eq(2)
      expect(sample.concentration_exponent).to eq(8)
      expect(sample.replicate).to eq(12)
      expect(sample.media).to eq("Other")
    end

    describe "assays" do
      it "saves attachment" do
        expect {
          get :new
          post :create, params: { sample: build_sample_form_plan(assay_attachments_attributes: [ {loinc_code_id: loinc_code.id, result: "foo bar"} ]) }
        }.to change{ institution.samples.count }.by(1)

        sample = institution.samples.first
        expect(sample.assay_attachments.size).to eq 1
        attachment = sample.assay_attachments.first
        expect(attachment.result).to eq "foo bar"
        expect(attachment.loinc_code).to eq loinc_code
      end

      it "errors on attachment error" do
        expect {
          get :new
          post :create, params: { sample: build_sample_form_plan(assay_attachments_attributes: [ {loinc_code_id: loinc_code.id } ]) }
        }.not_to change{ institution.samples.count }
        expect(@response.body).to include("must contain a file or a result")
      end
    end
  end

  context "edit" do
    let!(:sample) { Sample.make! institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e88')] }

    it "should be accessible by institution owner" do
      get :edit, params: { id: sample.id }
      expect(response).to be_success
      expect(assigns(:can_delete)).to be_truthy
    end

    it "should be accessible if can edit" do
      grant user, other_user, Sample, UPDATE_SAMPLE
      sign_in other_user

      get :edit, params: { id: sample.id }
      expect(response).to be_success
      expect(assigns(:can_delete)).to be_falsy
    end

    it "should not be accessible if can not edit" do
      sign_in other_user

      get :edit, params: { id: sample.id }
      expect(response).to be_forbidden
    end

    it "should allow to delete if can delete" do
      grant user, other_user, Sample, UPDATE_SAMPLE
      grant user, other_user, Sample, DELETE_SAMPLE
      sign_in other_user

      get :edit, params: { id: sample.id }
      expect(response).to be_success
      expect(assigns(:can_delete)).to be_truthy
    end

    it "shows old_batch_number" do
      sample.update(old_batch_number: "1234567")

      get :edit, params: { id: sample.id }

      expect(response.body).to include(sample.old_batch_number)
    end
  end

  context "update" do
    let!(:sample) { Sample.make!(institution: institution, sample_identifiers: [ SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e88')], date_produced:  Time.zone.local(2018, 1, 1)) }

    it "should update existing sample" do
      post :update, params: {
        id: sample.id,
        sample: {
          date_produced: '09/09/2021',
          isolate_name: 'ABC.42',
          lab_technician: 'TecFoo',
          specimen_role: 'q',
          inactivation_method: 'Formaldehyde',
          volume: '100'
        }
      }
      expect(response).to be_redirect

      sample.reload
      expect(sample.date_produced).to eq('09/09/2021')
      expect(sample.isolate_name).to eq('ABC.42')
      expect(sample.lab_technician).to eq('TecFoo')
      expect(sample.specimen_role).to eq('q')
      expect(sample.inactivation_method).to eq('Formaldehyde')
      expect(sample.volume).to eq('100')
    end

    it "should require date_produced" do
      post :update, params: { id: sample.id, sample: { date_produced: '' } }
      expect(assigns(:sample_form).errors).to have_key(:date_produced)
      expect(response).to render_template("samples/edit")
    end

    it "should update existing sample if allowed" do
      grant user, other_user, Sample, UPDATE_SAMPLE

      sign_in other_user
      post :update, params: {
        id: sample.id,
        sample: {
          date_produced: '09/09/2021',
          isolate_name: 'ABC.42',
          lab_technician: 'TecFoo',
          specimen_role: 'q',
          inactivation_method: 'Formaldehyde',
          volume: '100'
        }
      }
      expect(response).to be_redirect

      sample.reload
      expect(sample.date_produced).to eq('09/09/2021')
      expect(sample.isolate_name).to eq('ABC.42')
      expect(sample.lab_technician).to eq('TecFoo')
      expect(sample.specimen_role).to eq('q')
      expect(sample.inactivation_method).to eq('Formaldehyde')
      expect(sample.volume).to eq('100')
    end

    it "should not update existing sample if not allowed" do
      sign_in other_user
      post :update, params: { id: sample.id, sample: { date_produced: '09/09/2021' } }
      expect(response).to be_forbidden

      sample.reload
      expect(sample.date_produced).to_not eq('09/09/2021')
    end
  end

  context "destroy" do
    let!(:sample) { Sample.make!(institution: institution, sample_identifiers: [ SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e88')], date_produced:  Time.zone.local(2018, 1, 1)) }

    it "should be able to soft delete a sample" do
      expect {
        delete :destroy, params: { id: sample.id }
      }.to change(institution.samples, :count).by(-1)

      sample.reload
      expect(sample.deleted_at).to_not be_nil

      expect(response).to be_redirect
    end

    it "should be able to destroy if can delete" do
      grant user, other_user, Sample, DELETE_SAMPLE
      sign_in other_user

      expect {
        delete :destroy, params: { id: sample.id }
      }.to change(institution.samples, :count).by(-1)

      sample.reload
      expect(sample.deleted_at).to_not be_nil
    end

    it "should not able to destroy if can not delete" do
      sign_in other_user

      expect {
        delete :destroy, params: { id: sample.id }
      }.to change(institution.samples, :count).by(0)

      expect(response).to be_forbidden
    end
  end

  context "bulk_destroy" do
    let!(:sample1) { Sample.make!(institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e88')], date_produced: Time.zone.local(2018, 1, 1)) }
    let!(:sample2) { Sample.make!(institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e89')], date_produced: Time.zone.local(2018, 1, 1)) }

    let!(:institution2)   { Institution.make! }
    let!(:sample3) { Sample.make!(institution: institution2, sample_identifiers: [SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e90')], date_produced: Time.zone.local(2018, 1, 1)) }

    it "should be able to bulk destroy samples" do
      expect {
        post :bulk_destroy, params: { sample_ids: [sample1.id, sample2.id] }
      }.to change(institution.samples, :count).by(-2)

      sample1.reload
      expect(sample1.deleted_at).to_not be_nil
      sample2.reload
      expect(sample2.deleted_at).to_not be_nil

      expect(response).to be_redirect
    end

    it "should be able to bulk destroy if can DELETE" do
      grant user, other_user, Sample, DELETE_SAMPLE
      sign_in other_user

      expect {
        post :bulk_destroy, params: { sample_ids: [sample1.id, sample2.id] }
      }.to change(institution.samples, :count).by(-2)

      sample1.reload
      expect(sample1.deleted_at).to_not be_nil
      sample2.reload
      expect(sample2.deleted_at).to_not be_nil
    end

    it "should not able to bulk destroy if can not DELETE" do
      sign_in other_user

      expect {
        post :bulk_destroy, params: { sample_ids: [sample1.id, sample2.id] }
      }.to change(institution.samples, :count).by(0)

      expect(response).to be_forbidden
    end

    it "should not able to bulk destroy if can not DELETE all samples" do
      expect {
        post :bulk_destroy, params: { sample_ids: [sample1.id, sample2.id, sample3.id] }
      }.to change(institution.samples, :count).by(0)

      expect(response).to be_forbidden
    end
  end

  context "print" do
    let!(:sample) { Sample.make!(institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e88')], date_produced: Time.zone.local(2018, 1, 1)) }

    it "should be able to print a sample" do
      post :print, params: { id: sample.id }
      expect(response.headers['Content-Type']).to eq('application/pdf')
    end

    it "should be able to print if can READ" do
      grant user, other_user, Sample, READ_SAMPLE
      sign_in other_user

      post :print, params: { id: sample.id }
      expect(response.headers['Content-Type']).to eq('application/pdf')
    end

    it "should not able to print if can not READ" do
      sign_in other_user

      post :print, params: { id: sample.id }
      expect(response).to be_forbidden
    end
  end

  context "bulk_print" do
    let!(:sample1) { Sample.make!(institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e88')], date_produced: Time.zone.local(2018, 1, 1)) }
    let!(:sample2) { Sample.make!(institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e89')], date_produced: Time.zone.local(2018, 1, 1)) }

    let!(:institution2)   { Institution.make! }
    let!(:sample3) { Sample.make!(institution: institution2, sample_identifiers: [SampleIdentifier.make!(uuid: '01234567-8ce1-a0c8-ac1b-58bed3633e90')], date_produced: Time.zone.local(2018, 1, 1)) }

    it "should be able to bulk print samples" do
      post :bulk_print, params: { sample_ids: [sample1.id, sample2.id] }
      expect(response.headers['Content-Type']).to eq('application/pdf')
    end

    it "should be able to bulk print if can READ" do
      grant user, other_user, Sample, READ_SAMPLE
      sign_in other_user

      post :bulk_print, params: { sample_ids: [sample1.id, sample2.id] }
      expect(response.headers['Content-Type']).to eq('application/pdf')
    end

    it "should not able to bulk print if can not READ" do
      sign_in other_user

      post :bulk_print, params: { sample_ids: [sample1.id, sample2.id] }
      expect(response).to be_forbidden
    end

    it "should not able to bulk print if can not READ all samples" do
      post :bulk_print, params: { sample_ids: [sample1.id, sample2.id, sample3.id] }
      expect(response).to be_forbidden
    end
  end
end
