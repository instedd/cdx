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
    
    @box2 = Box.make!(:overfilled, institution: @institution, purpose: "Challenge")
    @samples_report2 = SamplesReport.create(institution: @institution, samples_report_samples: @box2.samples.map{|s| SamplesReportSample.new(sample: s)}, name: "TestChallenge")
    
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
    
      expect(response.headers["Content-Type"]).to eq("application/zip")
      expect(response.headers["Content-Disposition"]).to eq("attachment; filename=\"Test_nih_tables.zip\"")
    end
    
    it "should contain the Instructions.txt file" do
      get :show, params: { id: @samples_report.id }
      
      expect(Zip::File.open_buffer(response.body).entries.map(&:name)).to include("Instructions.txt")
    end

    it "should contain the samples & results table" do
      get :show, params: { id: @samples_report.id }

      expect(Zip::File.open_buffer(response.body).entries.map(&:name)).to include("#{@samples_report.name}_samples.csv")
      expect(Zip::File.open_buffer(response.body).entries.map(&:name)).to include("#{@samples_report.name}_results.csv")
    end

    it "should contain the samples table with the correct data" do
      get :show, params: { id: @samples_report.id }

      samples_table = CSV.parse(Zip::File.open_buffer(response.body).entries.find{|e| e.name == "Test_samples.csv"}.get_input_stream.read, headers: true)
      
      expect(samples_table.count).to eq(@samples_report.samples_report_samples.count)
      expect(samples_table["sample_id"]).to eq(@samples_report.samples_report_samples.map{|srs| srs.sample.uuid})
    end

    it "should contain the results table with the correct data" do
      get :show, params: { id: @samples_report.id }

      samples_table = CSV.parse(Zip::File.open_buffer(response.body).entries.find{|e| e.name == "Test_results.csv"}.get_input_stream.read, headers: true)
      
      expect(samples_table.count).to eq(@samples_report.samples_report_samples.count)
      expect(samples_table["sample_id"]).to eq(@samples_report.samples_report_samples.map{|srs| srs.sample.uuid.to_s})
    end

    it "should contain the LOD table for if the box purpose is LOD" do
      get :show, params: { id: @samples_report.id }

      expect(Zip::File.open_buffer(response.body).entries.map(&:name)).to include("Test_lod.csv")
    end

    it "should not contain the LOD table for if the box purpose is Challenge" do
      get :show, params: { id: @samples_report2.id }

      expect(Zip::File.open_buffer(response.body).entries.map(&:name)).not_to include("TestChallenge_lod.csv")
    end

    it "should contain the LOD table with the correct data" do
      get :show, params: { id: @samples_report.id }

      lod_table = CSV.parse(Zip::File.open_buffer(response.body).entries.find{|e| e.name == "Test_lod.csv"}.get_input_stream.read, headers: true)

      expect(lod_table.count).to eq(1)
      expect(lod_table["vqa_box_id"]).to include(@box.uuid)
    end

    it "should contain the Challenge table for if the box purpose is Challenge" do
      get :show, params: { id: @samples_report2.id }

      expect(Zip::File.open_buffer(response.body).entries.map(&:name)).to include("TestChallenge_challenge.csv")
    end

    it "should not contain the Challenge table for if the box purpose is LOD" do
      get :show, params: { id: @samples_report.id }

      expect(Zip::File.open_buffer(response.body).entries.map(&:name)).not_to include("Test_challenge.csv")
    end

    it "should contain the Challenge table with the correct data" do
      get :show, params: { id: @samples_report2.id }

      challenge_table = CSV.parse(Zip::File.open_buffer(response.body).entries.find{|e| e.name == "TestChallenge_challenge.csv"}.get_input_stream.read, headers: true)

      expect(challenge_table.count).to eq(1)
      expect(challenge_table["vqa_box_id"]).to include(@box2.uuid)
    end
    
    it "should not allow access to user without read access" do
      sign_in @other_user
      get :show, params: { id: @samples_report.id, context: @other_institution.uuid }
      expect(response).to have_http_status(:forbidden)
    end
  end
end