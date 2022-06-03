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

  describe "GET #index" do
    before(:each) { sign_in user }

    it "lists transfers" do
      transfer_in = TransferPackage.make!(sender_institution: institution, receiver_institution: other_institution)
      transfer_out = TransferPackage.make!(sender_institution: other_institution, receiver_institution: institution)
      transfer_unrelated = TransferPackage.make!

      get :index
      expect(response).to have_http_status :ok

      expect(response.body).to include(transfer_in.uuid)
      expect(response.body).to include(transfer_out.uuid)
      expect(response.body).not_to include(transfer_unrelated.uuid)
    end

    describe "filters" do
      let!(:subject) { TransferPackage.make!(sender_institution: institution) }
      let!(:other) { TransferPackage.make!(receiver_institution: institution) }

      it "by transfer id" do
        get :index, params: { search_uuid: subject.uuid[0..8] }
        expect(assigns(:transfer_packages).map(&:transfer_package)).to eq [subject]
      end

      it "by box id" do
        get :index, params: { search_uuid: subject.boxes.first.uuid[0..8] }
        expect(assigns(:transfer_packages).map(&:transfer_package)).to eq [subject]
      end

      it "by sample id" do
        get :index, params: { search_uuid: subject.samples.first.uuid[0..8] }
        expect(assigns(:transfer_packages).map(&:transfer_package)).to eq [subject]
      end

      it "by institution" do
        get :index, params: { institution: subject.receiver_institution.name }
        expect(assigns(:transfer_packages).map(&:transfer_package)).to eq [subject]

        get :index, params: { institution: other.sender_institution.name }
        expect(assigns(:transfer_packages).map(&:transfer_package)).to eq [other]
      end

      it "by status" do
        subject.update(confirmed_at: Time.now)
        get :index, params: { status: "confirmed" }
        expect(assigns(:transfer_packages).map(&:transfer_package)).to eq [subject]

        get :index, params: { status: "in transit" }
        expect(assigns(:transfer_packages).map(&:transfer_package)).to eq [other]
      end

      it "combined" do
        get :index, params: { search_uuid: subject.uuid[0..8], institution: subject.receiver_institution.name }
        expect(assigns(:transfer_packages).map(&:transfer_package)).to eq [subject]

        get :index, params: { search_uuid: subject.uuid[0..8], institution: subject.receiver_institution.name }
        expect(assigns(:transfer_packages).map(&:transfer_package)).to eq [subject]

        get :index, params: { search_uuid: subject.uuid[0..8], institution: other_institution.name }
        expect(assigns(:transfer_packages).map(&:transfer_package)).to be_empty
      end
    end
  end

  describe "GET #show" do
    before(:each) { sign_in user }

    let!(:transfer_out) { TransferPackage.make!(sender_institution: institution, receiver_institution: other_institution) }
    let!(:transfer_in) { TransferPackage.make!(sender_institution: other_institution, receiver_institution: institution) }
    let!(:transfer_other) { TransferPackage.make! }

    it "shows outgoing" do
      get :show, params: { id: transfer_out.id }

      expect(response).to have_http_status :ok
      expect(response.body).to include("Sent on")
      expect(response.body).to include(transfer_out.created_at.xmlschema)
    end

    it "shows incoming" do
      get :show, params: { id: transfer_in.id }

      expect(response).to have_http_status :ok
      expect(response.body).to include("Sent on")
      expect(response.body).to include(transfer_in.created_at.xmlschema)
    end

    it "doesn't show unrelated transfer" do
      expect {
        get :show, params: { id: transfer_other.id }
      }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #find_box" do
    let!(:sample) do
      Sample.make! :filled, institution: institution, sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-1111-a0c8-ac1b-58bed3633e88")]
    end

    let!(:box) do
      Box.make! institution: institution, samples: [sample], uuid: "01234567-1111-a0c8-ac1b-58bed3633e88"
    end

    let!(:other_sample) do
      Sample.make! :filled, institution: institution, created_at: sample.created_at - 1.day, sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-2222-a0c8-ac1b-58bed3633e88")]
    end

    let!(:other_box) do
      Box.make! institution: institution, samples: [other_sample], uuid: "01234567-2222-a0c8-ac1b-58bed3633e88"
    end

    let!(:other_institution_sample) do
      Sample.make! :filled, institution: other_institution, sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-9999-a0c8-ac1b-58bed3633e88")]
    end

    let!(:other_institution_box) do
      Box.make! institution: other_institution, samples: [other_institution_sample], uuid: "01234567-9999-a0c8-ac1b-58bed3633e88"
    end

    before(:each) { sign_in(user) }

    context "full UUID" do
      it "finds box" do
        get :find_box, params: { uuid: box.uuid }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["boxes"].map { |s| s["uuid"] }).to eq [box.uuid]
      end

      it "empty result when missing" do
        get :find_box, params: { uuid: "00000000-1111-2222-3333-444444444444" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["boxes"]).to be_empty
      end

      it "empty result when inaccessible" do
        get :find_box, params: { uuid: other_institution_box.uuid }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["boxes"]).to be_empty
      end

      it "checks read access" do
        sign_in other_user
        get :find_box, params: { uuid: box.uuid, context: other_institution.uuid }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["boxes"]).to be_empty
      end

      pending "adds error for QC sample" do
        qc_sample = Sample.make! :filled, institution: institution, specimen_role: "q", sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-4444-a0c8-ac1b-58bed3633e88")]

        get :find_box, params: { uuid: qc_sample.uuid }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["samples"].map { |s| s["uuid"] }).to eq [qc_sample.uuid]
        expect(data["samples"].map { |s| s["error"] }).to eq ["Sample 01234567-4444-a0c8-ac1b-58bed3633e88 is a QC sample and can't be transferred."]
      end
    end

    context "partial" do
      it "finds single box" do
        get :find_box, params: { uuid: "01234567-1" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["boxes"].map { |s| s["uuid"] }).to eq [box.uuid]
      end

      it "finds multiple boxes" do
        get :find_box, params: { uuid: "01234567" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["boxes"].map { |s| s["uuid"] }.sort).to eq [box.uuid, other_box.uuid]
      end

      it "empty result when missing" do
        get :find_box, params: { uuid: "00000000" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["boxes"]).to be_empty
      end

      it "empty result when inaccessible" do
        get :find_box, params: { uuid: "01234567-9999" }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["boxes"]).to be_empty
      end

      it "checks read access" do
        sign_in other_user
        get :find_box, params: { uuid: "01234567", context: other_institution.uuid }
        expect(response).to be_success

        data = JSON.parse(response.body)
        expect(data["boxes"].map { |s| s["uuid"] }).to eq [other_institution_box.uuid]
      end

      pending "adds error for QC box" do
        qc_sample = Sample.make! :filled, institution: institution, created_at: sample.created_at - 1.hour, specimen_role: "q", sample_identifiers: [SampleIdentifier.make!(uuid: "01234567-4444-a0c8-ac1b-58bed3633e88")]

        get :find_box, params: { uuid: "01234567" }
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
      batch = Batch.make!(:qc_sample)
      sample1 = Sample.make!(:filled, institution: institution, batch: batch)
      box1 = Box.make!(institution: institution, samples: [sample1])
      sample2 = Sample.make!(:filled, institution: institution)
      box2 = Box.make!(institution: institution, samples: [sample2])

      expect do
        post :create, params: {
                        transfer_package: {
                          receiver_institution_id: other_institution.id,
                          recipient: "Mr. X",
                          includes_qc_info: true,
                          box_transfers_attributes: {
                            "0" => {
                              box_id: box1.id,
                            },
                            "1" => {
                              box_id: box2.id,
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
      expect(package.boxes).to eq [box1, box2]

      sample1.reload
      sample2.reload
      expect(sample1.institution).to be_nil
      expect(sample2.institution).to be_nil

      box1.reload
      box2.reload
      expect(box1.institution).to be_nil
      expect(box2.institution).to be_nil

      expect(sample1.qc_info).not_to be_nil
      expect(sample2.qc_info).to be_nil

      expect(box1.blinded).to eq(false)
      expect(box2.blinded).to eq(false)
    end

    it "ignores blank sample_uuid" do
      sample = Sample.make!(:filled, institution: institution)
      box = Box.make!(institution: institution, samples: [sample])

      expect do
        post :create, params: {
                        transfer_package: {
                          receiver_institution_id: other_institution.id,
                          recipient: "Mr. X",
                          includes_qc_info: true,
                          box_transfers_attributes: {
                            "0" => {
                              box_id: box.id,
                            },
                            "1" => {
                              box_id: nil,
                            },
                            "2" => {
                              box_id: "",
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
      expect(package.boxes).to eq [box]
    end

    it "blinds boxes" do
      box1 = Box.make!(:filled, institution: institution, purpose: "LOD")
      box2 = Box.make!(:filled, institution: institution, purpose: "Variants")

      expect do
        post :create, params: {
                        transfer_package: {
                          receiver_institution_id: other_institution.id,
                          recipient: "Mr. X",
                          blinded: true,
                          box_transfers_attributes: {
                            "0" => { box_id: box1.id },
                            "1" => { box_id: box2.id },
                          },
                        },
                      }
      end.to change { TransferPackage.count }.by(1)

      expect(box1.reload.blinded).to eq(true)
      expect(box2.reload.blinded).to eq(true)
    end

    it "only allows samples in current institution" do
      box = Box.make!(institution: other_institution, samples: [Sample.make(:filled, institution: other_institution)])

      expect do
        post :create, params: {
                        transfer_package: {
                          receiver_institution_id: other_institution.id,
                          box_transfers_attributes: {
                            "0" => {
                              box_id: box.id,
                            },
                          },
                        },
                      }
        puts response.body
      end.to raise_error("User not authorized for transferring box #{box.uuid}")
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
      expect(response.body).to include("Box transfers must not be empty")
    end

    it "shows form again when missing receiver" do
      box = Box.make!(institution: institution, samples: [Sample.make!(:filled, institution: institution)])

      expect do
        post :create, params: {
                        transfer_package: {
                          box_transfers_attributes: {
                            "0" => {
                              box_id: box.id,
                            },
                          },
                        },
                      }
      end.not_to change { TransferPackage.count }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Destination can't be blank")
    end

    it "rejects unauthorized transfer" do
      unauthorized_user = User.make!
      grant user, unauthorized_user, institution, READ_INSTITUTION
      sign_in unauthorized_user

      box = Box.make!(institution: institution, samples: [Sample.make!(:filled, institution: institution)])

      expect do
        post :create, params: {
                        transfer_package: {
                          receiver_institution_id: other_institution.id,
                          box_transfers_attributes: {
                            "0" => {
                              box_id: box.id,
                            },
                          },
                        },
                      }
      end.to raise_error("User not authorized for transferring box #{box.uuid}")
    end
  end

  describe "unblind" do
    before(:each) { sign_in user }

    it "unblinds samples (transfer out)" do
      package = TransferPackage.make! sender_institution: institution, receiver_institution: other_institution, blinded: true

      post :unblind, params: { id: package.to_param }
      expect(response).to redirect_to(transfer_package_path(package))

      package.boxes.each do|box|
        expect(box.reload.blinded).to eq(false)
      end
    end

    it "won't unblind samples (transfer in)" do
      package = TransferPackage.make! sender_institution: other_institution, receiver_institution: institution, blinded: true

      assert_raises(ActiveRecord::RecordNotFound) do
        post :unblind, params: { id: package.to_param }
      end

      package.boxes.each do |box|
        expect(box.reload.blinded).to eq(true)
      end
    end
  end
end
