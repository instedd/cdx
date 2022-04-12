require "spec_helper"

RSpec.describe TransferPackagesController, type: :controller do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user

    @other_user = Institution.make!.user
    @other_institution = Institution.make! user: @other_user
  end

  let(:default_params) { { context: institution.uuid } }

  describe "GET #find_sample" do
    let!(:sample) do
      Sample.make! :filled, institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-1111-a0c8-ac1b-58bed3633e88")]
    end

    let!(:other_sample) do
      Sample.make! :filled, institution: institution, created_at: sample.created_at - 1.day, sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-2222-a0c8-ac1b-58bed3633e88")]
    end

    let!(:other_institution_sample) do
      Sample.make! :filled, institution: other_institution, sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-9999-a0c8-ac1b-58bed3633e88")]
    end

    before(:each) { sign_in(user) }

    context "full UUID" do
      it "finds sample" do
        get :find_sample, params: { uuid: sample.uuid }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"].map { |s| s["uuid"] }).to eq [sample.uuid]
      end

      it "empty result when missing" do
        get :find_sample, params: { uuid: "00000000-1111-2222-3333-444444444444" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"]).to be_empty
      end

      it "empty result when inaccessible" do
        get :find_sample, params: { uuid: other_institution_sample.uuid }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"]).to be_empty
      end

      it "checks read access" do
        sign_in other_user
        get :find_sample, params: { uuid: sample.uuid, context: other_institution.uuid }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"]).to be_empty
      end

      it "does not include QC sample" do
        qc_sample = Sample.make! :filled, institution: institution, specimen_role: "q", sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-4444-a0c8-ac1b-58bed3633e88")]

        get :find_sample, params: { uuid: qc_sample.uuid }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"]).to be_nil
        expect(data["error"]).to eq "Sample 01234567-4444-a0c8-ac1b-58bed3633e88 is a QC sample and can't be transferred."
      end
    end

    context "partial" do
      it "finds single sample" do
        get :find_sample, params: { uuid: "01234567-1" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"].map { |s| s["uuid"] }).to eq [sample.uuid]
      end

      it "finds multiple samples" do
        get :find_sample, params: { uuid: "01234567" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"].map { |s| s["uuid"] }).to eq [sample.uuid, other_sample.uuid]
      end

      it "empty result when missing" do
        get :find_sample, params: { uuid: "00000000" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"]).to be_empty
      end

      it "empty result when inaccessible" do
        get :find_sample, params: { uuid: "01234567-9999" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"]).to be_empty
      end

      it "checks read access" do
        sign_in other_user
        get :find_sample, params: { uuid: "01234567", context: other_institution.uuid }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"].map { |s| s["uuid"] }).to eq [other_institution_sample.uuid]
      end

      it "does not include QC sample" do
        Sample.make! :filled, institution: institution, specimen_role: "q", sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-4444-a0c8-ac1b-58bed3633e88")]

        get :find_sample, params: { uuid: "01234567" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"].map { |s| s["uuid"] }).to eq [sample.uuid, other_sample.uuid]
      end
    end
  end
end
