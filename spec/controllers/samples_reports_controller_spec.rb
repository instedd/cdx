require 'spec_helper'
require 'policy_spec_helper'

RSpec.describe SamplesReportsController, type: :controller do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
    @other_user = User.make!
    @other_institution = Institution.make! user: @other_user

    @box = Box.make!(:overfilled, institution: @institution, purpose: "LOD")


    concentrations = @box.samples.map(&:concentration)
    signals = Numo::DFloat[*@box.samples.map(&:measured_signal)]

    puts concentrations.inspect
    puts signals.inspect

    @box2 = Box.make!(:filled, institution: @institution, purpose: "Challenge")
    @box_without_measurements = Box.make!(:filled_without_measurements, institution: @institution, purpose: "LOD")

    @samples_report = SamplesReport.create(institution: @institution, samples_report_samples: @box.samples.map{|s| SamplesReportSample.new(sample: s)}, name: "Test")
    @samples_report2 = SamplesReport.create(institution: @institution, samples_report_samples: @box2.samples.map{|s| SamplesReportSample.new(sample: s)}, name: "Test2")

    grant @user, @other_user, @institution, READ_INSTITUTION
  end

  let(:default_params) do
    { context: institution.uuid }
  end

  before(:each) do
    sign_in user
  end

  describe "show" do
    it "should be accessible to institution owner" do
      get :show, params: { id: samples_report.id }
      expect(response).to have_http_status(:ok)
    end

    it "should be allowed if can read" do
      grant user, other_user, samples_report, READ_SAMPLES_REPORT
      sign_in other_user

      get :show, params: { id: samples_report.id }
      expect(response).to have_http_status(:ok)
    end

    it "shouldn't be allowed if can't read" do
      sign_in other_user

      get :show, params: { id: samples_report.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "new" do
    it "should be accessible to institution owner" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "should be allowed if can create" do
      grant @user, @other_user, @institution, CREATE_INSTITUTION_SAMPLES_REPORT
      sign_in other_user

      get :new
      expect(response).to have_http_status(:ok)
    end

    it "shouldn't be allowed if can't create" do
      sign_in other_user

      get :new
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "create" do
    it "should create samples report" do
      expect do
        post :create, params: { samples_report: { name: "Test", box_ids: [@box.id] } }
        expect(response).to redirect_to samples_reports_path
      end.to change(institution.samples_reports, :count).by(1)
    end

    it "should create samples report if allowed" do
      grant user, other_user, institution, CREATE_INSTITUTION_SAMPLES_REPORT
      grant user, other_user, box, READ_BOX
      sign_in other_user

      expect do
        post :create, params: { samples_report: { name: "Test", box_ids: [@box.id] } }
        expect(response).to redirect_to samples_reports_path
      end.to change(institution.samples_reports, :count).by(1)
    end

    it "should not create samples report if not allowed" do
      sign_in other_user

      expect do
        post :create, params: { samples_report: { name: "Test", samples_report_samples_attributes: @box.samples.map{|s| {sample_id: s.id}} } }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.samples_reports, :count).by(0)
    end

    it "should not create samples report if there is no measurements" do
      sign_in other_user

      expect do
        post :create, params: { samples_report: { name: "TestWithoutMeasurements", samples_report_samples_attributes: @box_without_measurements.samples.map{|s| {sample_id: s.id}} } }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.samples_reports, :count).by(0)
    end


  end

  describe "index" do
    it "should be accessible by institution owner" do
      get :index
      expect(response).to have_http_status(:ok)
      expect(assigns(:samples_reports).count).to eq(2)
    end

    it "should not list samples reports if can not read" do
      sign_in other_user

      get :index
      expect(assigns(:samples_reports).count).to eq(0)
    end
  end

  describe "filters" do
    it "by report name" do
      get :index, params: { name: "Test2" }
      expect(response).to have_http_status(:ok)
      expect(assigns(:samples_reports).count).to eq(1)
    end

    it "by sample uuid" do
      get :index, params: { sample_uuid: @box.samples.first.uuid }
      expect(response).to have_http_status(:ok)
      expect(assigns(:samples_reports).count).to eq(1)
    end

    it "by batch number" do
      get :index, params: { batch_number: @box.samples.first.batch.batch_number }
      expect(response).to have_http_status(:ok)
      expect(assigns(:samples_reports).length).to eq(1)
    end

    it "by box uuid" do
      get :index, params: { box_uuid: @box.uuid }
      expect(response).to have_http_status(:ok)
      expect(assigns(:samples_reports).length).to eq(1)
    end

  end

  describe "delete" do
    it "should delete samples report" do
      expect do
        delete :delete, params: { id: @samples_report.id }
        expect(response).to redirect_to samples_reports_path
      end.to change(institution.samples_reports, :count).by(-1)
    end

    it "should delete samples report if allowed" do
      grant user, other_user, samples_report, DELETE_SAMPLES_REPORT
      sign_in other_user

      expect do
        delete :delete, params: { id: @samples_report.id }
        expect(response).to redirect_to samples_reports_path
      end.to change(institution.samples_reports, :count).by(-1)

      expect(samples_report.reload.deleted_at).to_not be_nil
    end

    it "should not delete box if not allowed" do
      sign_in other_user

      expect do
        delete :delete, params: { id: @samples_report.id }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.samples_reports.unscoped, :count).by(0)
    end
  end

  describe "bulk_destroy" do
    it "should delete samples reports" do
      expect do
        post :bulk_destroy, params: { samples_report_ids: [@samples_report.id, @samples_report2.id] }
        expect(response).to redirect_to samples_reports_path
      end.to change(institution.samples_reports, :count).by(-2)

      expect(@samples_report.reload.deleted_at).to_not be_nil
      expect(@samples_report2.reload.deleted_at).to_not be_nil
    end

     it "should delete samples reports if allowed" do
       grant user, other_user, @samples_report, DELETE_SAMPLES_REPORT
       grant user, other_user, @samples_report2, DELETE_SAMPLES_REPORT
       sign_in other_user

       expect do
        post :bulk_destroy, params: { samples_report_ids: [@samples_report.id, @samples_report2.id] }
        expect(response).to redirect_to samples_reports_path
      end.to change(institution.samples_reports, :count).by(-2)

      expect(@samples_report.reload.deleted_at).to_not be_nil
      expect(@samples_report2.reload.deleted_at).to_not be_nil
    end

    it "should not delete samples reports if not all allowed" do
      grant user, other_user, @samples_report, DELETE_SAMPLES_REPORT
      sign_in other_user

      expect do
        post :bulk_destroy, params: { samples_report_ids: [@samples_report2.id] }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.samples_reports, :count).by(0)
    end

    it "should not delete samples reports if not allowed" do
      sign_in other_user

      expect do
        post :bulk_destroy, params: { samples_report_ids: [@samples_report.id, @samples_report2.id] }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.samples_reports, :count).by(0)
    end
  end
end
