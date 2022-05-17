require "spec_helper"

RSpec.describe TransferPackagesController, type: :controller do
  setup_fixtures do
    @institution = Institution.make!
    @user = @institution.user

    @other_institution = Institution.make!
    @other_user = @other_institution.user
    grant @other_user, @user, @other_institution, READ_INSTITUTION
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

      it "adds error for QC sample" do
        qc_sample = Sample.make! :filled, institution: institution, specimen_role: "q", sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-4444-a0c8-ac1b-58bed3633e88")]

        get :find_sample, params: { uuid: qc_sample.uuid }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"].map { |s| s["uuid"] }).to eq [qc_sample.uuid]
        expect(data["samples"].map { |s| s["error"] }).to eq ["Sample 01234567-4444-a0c8-ac1b-58bed3633e88 is a QC sample and can't be transferred."]
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

      it "adds error for QC sample" do
        qc_sample = Sample.make! :filled, institution: institution, created_at: sample.created_at - 1.hour, specimen_role: "q", sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-4444-a0c8-ac1b-58bed3633e88")]

        get :find_sample, params: { uuid: "01234567" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"].map { |s| s["uuid"] }).to eq [sample.uuid, qc_sample.uuid, other_sample.uuid]
        expect(data["samples"].map { |s| s["error"] }).to eq [nil, "Sample 01234567-4444-a0c8-ac1b-58bed3633e88 is a QC sample and can't be transferred.", nil]
      end
    end
  end

  describe "GET #new" do
    before(:each) { sign_in(user) }
    let(:default_params) { { context: institution.uuid } }

    it "should be accessible be institution owner" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "should be allowed it can create" do
      # grant other_institution.user, user, other_institution, CREATE_INSTITUTION_SAMPLE
      get :new, params: { context: other_institution.uuid }
      expect(response).to have_http_status(:ok)
    end

    pending "should not be allowed it can not create" do
      get :new, params: { context: other_institution.uuid }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST #create" do
    before(:each) { sign_in(user) }
    let(:default_params) { { context: institution.uuid } }

    it "creates transfer package" do
      sample1 = Sample.make!(:filled, institution: institution)
      sample2 = Sample.make!(:filled, institution: institution)

      expect do
        post :create, params: {
                        transfer_package: {
                          receiver_institution_id: other_institution.id,
                          recipient: "Mr. X",
                          includes_qc_info: true,
                          sample_transfers_attributes: {
                            "0" => {
                              sample_id: sample1.id,
                            },
                            "1" => {
                              sample_id: sample2.id,
                            },
                          },
                        },
                      }
      end.to change { TransferPackage.count }.by(1)

      package = TransferPackage.last
      expect(package.recipient).to eq "Mr. X"
      expect(package.sender_institution).to eq institution
      expect(package.receiver_institution).to eq other_institution
      expect(package.includes_qc_info?).to eq true
      expect(package.sample_transfers.map(&:sample)).to eq [sample1, sample2]
    end

    it "ignores blank sample_uuid" do
      sample = Sample.make!(:filled, institution: institution)

      expect do
        post :create, params: {
                        transfer_package: {
                          receiver_institution_id: other_institution.id,
                          recipient: "Mr. X",
                          includes_qc_info: true,
                          sample_transfers_attributes: {
                            "0" => {
                              sample_id: sample.id,
                            },
                            "1" => {
                              sample_id: nil,
                            },
                            "2" => {
                              sample_id: "",
                            },
                          },
                        },
                      }
      end.to change { TransferPackage.count }.by(1)

      package = TransferPackage.last
      expect(package.recipient).to eq "Mr. X"
      expect(package.sender_institution).to eq institution
      expect(package.receiver_institution).to eq other_institution
      expect(package.includes_qc_info?).to eq true
      expect(package.sample_transfers.map(&:sample)).to eq [sample]
    end

    it "only allows samples in current institution" do
      sample = Sample.make!(:filled, institution: other_institution)

      expect do
        post :create, params: {
                        transfer_package: {
                          receiver_institution_id: other_institution.id,
                          sample_transfers_attributes: {
                            "0" => {
                              sample_id: sample.id,
                            },
                          },
                        },
                      }
      end.to raise_error("User not authorized for transferring sample #{sample.uuid}")
    end

    it "shows form again when empty samples" do
      expect do
        post :create, params: {
                        transfer_package: {
                          receiver_institution_id: other_institution.id,
                        },
                      }
      end.not_to change { TransferPackage.count }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Samples must not be empty")
    end

    it "shows form again when missing receiver" do
      sample = Sample.make!(:filled, institution: institution)

      expect do
        post :create, params: {
                        transfer_package: {
                          sample_transfers_attributes: {
                            "0" => {
                              sample_id: sample.id,
                            },
                          },
                        },
                      }
      end.not_to change { TransferPackage.count }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Destination can't be blank")
    end

    it "rejects transferring QC sample" do
      sample = Sample.make!(:filled, institution: institution, specimen_role: "q")

      expect do
        post :create, params: {
                        transfer_package: {
                          receiver_institution_id: other_institution.id,
                          sample_transfers_attributes: {
                            "0" => {
                              sample_id: sample.id,
                            },
                          },
                        },
                      }
      end.not_to change{ TransferPackage.count }
    end

    it "rejects unauthorized transfer" do
      unauthorized_user = User.make!
      grant user, unauthorized_user, institution, READ_INSTITUTION
      sign_in unauthorized_user

      sample = Sample.make!(:filled, institution: institution)

      expect do
        post :create, params: {
                        transfer_package: {
                          receiver_institution_id: other_institution.id,
                          sample_transfers_attributes: {
                            "0" => {
                              sample_id: sample.id,
                            },
                          },
                        },
                      }
      end.to raise_error("User not authorized for transferring sample #{sample.uuid}")
    end
  end
end
