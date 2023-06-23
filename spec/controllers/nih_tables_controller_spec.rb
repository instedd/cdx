require 'spec_helper'
require 'policy_spec_helper'

RSpec.describe NihTablesController, type: :controller do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
    @other_user = User.make!
    @other_institution = Institution.make! user: @other_user
    
    @box = Box.make!(:overfilled, institution: @institution, purpose: "LOD")
    @samples_report = SamplesReport.create(institution: @institution, samples_report_samples: @box.samples.map{|s| SamplesReportSample.new(sample: s)}, name: "Test")
    
    grant @user, @other_user, @other_institution, READ_INSTITUTION
  end

  let(:default_params) do
    { context: @institution.uuid }
  end

  before(:each) do
    sign_in @user
  end 

  describe "show" do
    it "should download a zip file on show" do
      get :show, params: { id: @samples_report.id } 
    
      #expect sent file to be a zip file
      expect(response.headers["Content-Type"]).to eq("application/zip")
      expect(response.headers["Content-Disposition"]).to eq("attachment; filename=\"Test_nih_tables.zip\"")
    end
    
    it "should contain the Instructions.txt file" do
      get :show, params: { id: @samples_report.id }
      
      #expect the zip file to contain the Instructions.txt file
      expect(Zip::File.open_buffer(response.body).entries.map(&:name)).to include("Instructions.txt")
    end

    it "should not allow access to user without read access" do
      sign_in @other_user
      get :show, params: { id: @samples_report.id, context: @other_institution.uuid }
      expect(response).to have_http_status(:forbidden)
    end
  end
end