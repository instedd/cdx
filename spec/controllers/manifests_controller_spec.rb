require 'spec_helper'

describe ManifestsController do
  let(:user) {User.make}
  before(:each) {sign_in user}
  let!(:institution) { user.create Institution.make_unsaved }

  context "Creation" do

    it "shouldn't create if JSON is not valid" do
      json = {"definition" => %{
        { , , }
      } }
      expect(Manifest.count).to eq(0)
      post :create, manifest: json
      expect(Manifest.count).to eq(0)
    end

    it "should create if is a valid manifest" do
      json = {"definition" => %{{
        "metadata": {
          "version" : "1.0.0",
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "device_models" : ["GX4001"],
          "conditions": ["mtb"],
          "source" : { "type" : "json" }
        },
        "field_mapping": {
          "test.assay_name" : {"lookup" : "Test.assay_name"},
          "test.type" : {
            "case" : [
              {"lookup" : "Test.test_type"},
              [
                {"when" : "*QC*", "then" : "qc"},
                {"when" : "*Specimen*", "then" : "specimen"}
              ]
            ]
          }
        }
      }}}
      expect(Manifest.count).to eq(0)
      post :create, manifest: json
      expect(Manifest.count).to eq(1)
    end
  end
end


