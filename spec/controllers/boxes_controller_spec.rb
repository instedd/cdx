require 'spec_helper'
require 'policy_spec_helper'

RSpec.describe BoxesController, type: :controller do
  setup_fixtures do
    @user = User.make!

    @institution = Institution.make! user: @user
    @box = Box.make! institution: @institution

    @site = Site.make! institution: @institution
    @site_box = Box.make! institution: @institution, site: @site

    @other_user = Institution.make!.user
    grant @user, @other_user, @institution, READ_INSTITUTION
  end

  let(:default_params) do
    { context: institution.uuid }
  end

  before(:each) { sign_in user }

  describe "index" do
    it "should be accessible by institution owner" do
      get :index
      expect(response).to have_http_status(:ok)
      expect(assigns(:boxes).count).to eq(2)
    end

    it "should not list boxes if can not read" do
      sign_in other_user

      get :index
      expect(assigns(:boxes).count).to eq(0)
    end

    describe "filters" do
      before(:each) do
        Box.make!(3, institution: @institution, purpose: "LOD")
        Box.make!(2, institution: @institution, purpose: "Variants")
        Box.make!(4, institution: @institution, purpose: "Challenge")
      end

      it "paginates" do
        get :index
        expect(assigns(:boxes).count).to eq(10)
      end

      it "by site" do
        get :index, params: { context: "#{site.uuid}-*" }
        expect(response).to have_http_status(:ok)
        expect(assigns(:boxes).count).to eq(1)
      end

      it "by site excluding subsites" do
        get :index, params: { context: "#{site.uuid}-!" }
        expect(response).to have_http_status(:ok)
        expect(assigns(:boxes).count).to eq(1)
      end

      it "by uuid" do
        get :index, params: { uuid: @box.uuid[0..6] }
        expect(assigns(:boxes).count).to eq(1)
      end

      it "by purpose" do
        get :index, params: { purpose: "LOD" }
        expect(assigns(:boxes).count).to eq(5)

        get :index, params: { purpose: "Variants" }
        expect(assigns(:boxes).count).to eq(2)

        get :index, params: { purpose: "Challenge" }
        expect(assigns(:boxes).count).to eq(4)
      end
    end
  end

  describe "show" do
    it "should be accessible to institution owner" do
      get :show, params: { id: box.id }
      expect(response).to have_http_status(:ok)
    end

    it "should be allowed if can read" do
      grant user, other_user, box, READ_BOX
      sign_in other_user

      get :show, params: { id: box.id }
      expect(response).to have_http_status(:ok)
    end

    it "shouldn't be allowed if can't read" do
      sign_in other_user

      get :show, params: { id: box.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "print" do
    before do
      stub_request(:get, %r{https://fonts\.googleapis\.com/.*}).to_return(body: "")
    end

    it "should be accessible to institution owner" do
      get :print, params: { id: box.id }
      expect(response).to have_http_status(:ok)
    end

    it "should be allowed if can read" do
      grant user, other_user, box, READ_BOX
      sign_in other_user

      get :print, params: { id: box.id }
      expect(response).to have_http_status(:ok)
    end

    it "shouldn't be allowed if can't read" do
      sign_in other_user

      get :print, params: { id: box.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "new" do
    it "should be accessible to institution owner" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "should be allowed if can create" do
      grant user, other_user, institution, CREATE_INSTITUTION_BOX
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
    let :batch do
      Batch.make!(institution: institution, site: site)
    end

    let :box_plan do
      {
        purpose: "LOD",
        batch_numbers: { "lod" => batch.batch_number },
      }
    end

    it "should create box in context institution" do
      expect do
        post :create, params: { box: box_plan }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(1)

      box = assigns(:box_form).box.reload
      expect(box.uuid).to_not be_nil
      expect(box.institution_id).to eq institution.id
    end

    it "should create box in context site" do
      default_params[:context] = site.uuid

      expect do
        post :create, params: { box: box_plan }
        expect(response).to redirect_to boxes_path
      end.to change(site.boxes, :count).by(1)

      box = assigns(:box_form).box.reload
      expect(box.uuid).to_not be_nil
      expect(box.institution_id).to eq institution.id
      expect(box.site_id).to eq site.id
    end

    it "should create box if allowed" do
      grant user, other_user, institution, CREATE_INSTITUTION_BOX
      grant user, other_user, batch, READ_BATCH
      sign_in other_user

      expect do
        post :create, params: { box: box_plan }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(1)
    end

    it "should not create box if not allowed" do
      sign_in other_user

      expect do
        post :create, params: { box: box_plan }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.boxes, :count).by(0)
    end

    def expect_samples(batch, concentration_exponents:, replicates:)
      samples = batch.samples.order(:id).to_a
      expect(samples.size).to eq(concentration_exponents.size * replicates)

      concentration_exponents.each do |e|
        1.upto(replicates) do |r|
          expect(sample = samples.shift).to_not be_nil
          expect(sample.concentration).to eq(1 * (10 ** -e))
          expect(sample.replicate).to eq(r)
        end
      end
    end

    describe "LOD purpose" do
      it "creates samples" do
        expect do
          post :create, params: { box: {
            purpose: "LOD",
            batch_numbers: { "lod" => batch.batch_number },
          } }
          expect(response).to redirect_to(boxes_path)
        end.to change(institution.samples, :count).by(24)

        expect(Box.last.samples.count).to eq(24)
        expect_samples(batch, concentration_exponents: 1..8, replicates: 3)
      end

      it "requires one batch" do
        expect do
          post :create, params: { box: {
            purpose: "LOD",
            batch_numbers: { "lod" => "" },
          } }
          expect(response).to have_http_status(:unprocessable_entity)
        end.to change(institution.samples, :count).by(0)
      end
    end

    describe "Variants purpose" do
      it "creates samples" do
        batches = Batch.make!(6, institution: institution)
        batch_numbers = Hash[batches.map.with_index { |b, i| ["variant_#{i}", b.batch_number] }]

        expect do
          post :create, params: { box: {
            purpose: "Variants",
            batch_numbers: batch_numbers,
          } }
          expect(response).to redirect_to(boxes_path)
        end.to change(institution.samples, :count).by(54)

        expect(Box.last.samples.count).to eq(54)
        batches.each do |b|
          expect_samples(b, concentration_exponents: [1, 4, 8], replicates: 3)
        end
      end

      it "requires at least 2 variant batches" do
        expect do
          post :create, params: { box: {
            purpose: "Variants",
            batch_numbers: { "variant_1" => batch.batch_number },
          } }
          expect(response).to have_http_status(:unprocessable_entity)
        end.to change(institution.samples, :count).by(0)
      end

      it "creates samples from 2 batches" do
        other_batch = Batch.make!(institution: institution)

        expect do
          post :create, params: { box: {
            purpose: "Variants",
            batch_numbers: {
              "variant_4" => batch.batch_number,
              "variant_2" => other_batch.batch_number,
            },
          } }
          expect(response).to redirect_to(boxes_path)
        end.to change(institution.samples, :count).by(18)
      end
    end

    describe "Challenge purpose" do
      it "creates samples" do
        batches = Batch.make!(6, institution: institution)
        batch_numbers = { "virus" => batch.batch_number }
        batches.each_with_index { |b, i| batch_numbers["distractor_#{i + 1}"] = b.batch_number }

        expect do
          post :create, params: { box: {
            purpose: "Challenge",
            batch_numbers: batch_numbers,
          } }
          expect(response).to redirect_to(boxes_path)
        end.to change(institution.samples, :count).by(108)

        expect(Box.last.samples.count).to eq(108)

        # virus batch
        expect_samples(batch, concentration_exponents: [1, 4, 8], replicates: 18)

        # distractor batches
        batches.each do |b|
          expect_samples(b, concentration_exponents: [1, 4, 8], replicates: 3)
        end
      end

      it "requires a virus batch" do
        distractor = Batch.make!(institution: institution)

        expect do
          post :create, params: { box: {
            purpose: "Challenge",
            batch_numbers: { "1" => distractor.batch_number },
          } }
          expect(response).to have_http_status(:unprocessable_entity)
        end.to change(institution.samples, :count).by(0)
      end

      it "requires at least 1 distractor batches" do
        expect do
          post :create, params: { box: {
            purpose: "Challenge",
            batch_numbers: { "virus" => batch.batch_number },
          } }
          expect(response).to have_http_status(:unprocessable_entity)
        end.to change(institution.samples, :count).by(0)
      end

      it "creates samples from 1 virus batch and 1 distractor batches" do
        distractor = Batch.make!(institution: institution)

        expect do
          post :create, params: { box: {
            purpose: "Challenge",
            batch_numbers: {
              "virus" => batch.batch_number,
              "distractor_4" => distractor.batch_number,
            },
          } }
          expect(response).to redirect_to(boxes_path)
        end.to change(institution.samples, :count).by(63)
      end
    end
  end

  describe "destroy" do
    it "should delete box" do
      expect do
        delete :destroy, params: { id: box.id }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(-1)
    end

    it "should delete box if allowed" do
      grant user, other_user, box, DELETE_BOX
      sign_in other_user

      expect do
        delete :destroy, params: { id: box.id }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(-1)

      expect(box.reload.deleted_at).to_not be_nil
    end

    it "should not delete box if not allowed" do
      sign_in other_user

      expect do
        delete :destroy, params: { id: box.id }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.boxes.unscoped, :count).by(0)
    end
  end

  describe "bulk_destroy" do
    it "should delete boxes" do
      expect do
        post :bulk_destroy, params: { box_ids: [box.id, site_box.id] }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(-2)

      expect(box.reload.deleted_at).to_not be_nil
      expect(site_box.reload.deleted_at).to_not be_nil
    end

    it "should delete boxes if allowed" do
      grant user, other_user, box, DELETE_BOX
      grant user, other_user, site_box, DELETE_BOX
      sign_in other_user

      expect do
        post :bulk_destroy, params: { box_ids: [box.id, site_box.id] }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(-2)

      expect(box.reload.deleted_at).to_not be_nil
      expect(site_box.reload.deleted_at).to_not be_nil
    end

    it "should not delete boxes if not all allowed" do
      grant user, other_user, box, DELETE_BOX
      sign_in other_user

      expect do
        post :bulk_destroy, params: { box_ids: [box.id, site_box.id] }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.boxes, :count).by(0)
    end

    it "should not delete boxes if not allowed" do
      sign_in other_user

      expect do
        post :bulk_destroy, params: { box_ids: [box.id, site_box.id] }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.boxes.unscoped, :count).by(0)
    end
  end
end
