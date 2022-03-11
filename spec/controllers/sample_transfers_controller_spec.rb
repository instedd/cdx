require "spec_helper"

RSpec.describe SampleTransfersController, type: :controller do
  let!(:my_institution) { Institution.make! }
  let!(:other_institution) { Institution.make! }
  let!(:current_user) { my_institution.user }
  let(:default_params) { { context: my_institution.uuid } }

  describe "GET #index" do
    before(:each) do
      sign_in current_user
    end

    it "includes transfers from and to my institution (ordered by creation date)" do
      sample_transfers = [
        SampleTransfer.make!(sender_institution: my_institution, created_at: Time.now - 1.day),
        SampleTransfer.make!(receiver_institution: my_institution, created_at: Time.now),
      ]
      get :index
      expect(assigns(:sample_transfers).map(&:transfer)).to eq sample_transfers.reverse
    end

    it "excludes transfers not from or to my institution" do
      SampleTransfer.make!
      get :index
      expect(assigns(:sample_transfers)).to be_empty
    end

    describe "filters" do
      let!(:subject) { SampleTransfer.make!(sender_institution: my_institution, sample: Sample.make!(:filled, batch: Batch.make!, specimen_role: "c")) }
      let!(:other) { SampleTransfer.make!(receiver_institution: my_institution, sample: Sample.make!(:filled, batch: Batch.make!)) }

      it "by sample id" do
        get :index, sample_id: subject.sample.uuid[0..8]
        expect(assigns(:sample_transfers).map(&:transfer)).to eq [subject]
      end

      it "by batch_name" do
        get :index, batch_number: subject.sample.batch.batch_number
        expect(assigns(:sample_transfers).map(&:transfer)).to eq [subject]
      end

      it "by isolate_name" do
        get :index, isolate_name: subject.sample.isolate_name
        expect(assigns(:sample_transfers).map(&:transfer)).to eq [subject]
      end

      it "by specimen_role" do
        get :index, specimen_role: subject.sample.specimen_role
        expect(assigns(:sample_transfers).map(&:transfer)).to eq [subject]
      end

      it "combined" do
        get :index, sample_id: subject.sample.uuid[0..8], batch_number: subject.sample.batch.batch_number, isolate_name: subject.sample.isolate_name, specimen_role: subject.sample.specimen_role
        expect(assigns(:sample_transfers).map(&:transfer)).to eq [subject]
      end
    end
  end
end
