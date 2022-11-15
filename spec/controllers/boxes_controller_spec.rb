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
        Box.make!(3, :filled, institution: @institution, purpose: "LOD")
        Box.make!(2, :filled, institution: @institution, purpose: "Variants")
        Box.make!(4, :filled, institution: @institution, purpose: "Challenge")
        Box.make!(1, :filled, institution: @institution, purpose: "Other")
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

        get :index, params: { purpose: "Other" }
        expect(assigns(:boxes).count).to eq(1)
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

  describe "inventory" do
    it "should be accessible to institution owner" do
      get :inventory, params: { id: box.id, format: "csv" }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("text/csv")
      expect(response.body.strip.split("\n").size).to eq(box.samples.count + 1)
      expect(response.body).to_not match("Blinded")
      expect(response.headers["Content-Disposition"]).to match(/cdx_box_inventory_#{box.uuid}\.csv/)
    end

    it "should be ordered by batch_number, concentration, replicate ASC" do
      get :inventory, params: { id: box.id, format: "csv" }
      expect(response).to have_http_status(:ok)
      results = CSV.parse(response.body).tap(&:shift).map do |row|
        { :batch_number => row[3], :concentration => row[6], :replicate => row[7] }
      end
      expect( results ).to eq( results.sort_by{ |sample|  [ sample[:batch_number], sample[:concentration], sample[:replicate] ] } )
    end

    it "should be allowed if can read" do
      grant user, other_user, box, READ_BOX
      sign_in other_user

      get :inventory, params: { id: box.id, format: "csv" }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("text/csv")
    end

    it "shouldn't be allowed if can't read" do
      sign_in other_user
      get :inventory, params: { id: box.id, format: "csv" }
      expect(response).to have_http_status(:forbidden)
    end

    it "blinds columns for Samples" do
      box = Box.make! :filled, institution: institution, blinded: true

      get :inventory, params: { id: box.id, format: "csv" }
      expect(response).to have_http_status(:ok)

      CSV.parse(response.body).tap(&:shift).each do |row|
        expect(row[3]).to eq("Blinded")
        expect(row[4]).to eq("Blinded")
        expect(row[5]).to eq("Blinded")
        expect(row[7]).to eq("Blinded")
      end
    end

    it "don't blind columns for unblinded inventory" do
      box = Box.make! :filled, institution: institution, blinded: true

      get :inventory, params: { id: box.id, format: "csv", unblind: true }
      expect(response).to have_http_status(:ok)

      CSV.parse(response.body).tap(&:shift).each do |row|
        expect(row[3]).not_to eq("Blinded")
        expect(row[4]).not_to eq("Blinded")
        expect(row[5]).not_to eq("Blinded")
        expect(row[7]).not_to eq("Blinded")
      end
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
        batch_uuids: { "lod" => batch.uuid },
        blinded: true,
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

    it "should create box with optional params" do
      expect do
        post :create, params: { box: box_plan.merge(media: "Saliva", blinded: true) }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(1)

      box = assigns(:box_form).box.reload
      expect(box.samples.map(&:media).uniq).to eq(["Saliva"])
      expect(box.blinded).to eq true
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

    def expect_samples(batch, concentrations: [1], replicates:)
      # NOTE: can't where/order in SQL because entity fields...
      concentrations.each do |c|
        samples = batch.samples.to_a
          .reject { |s| s.concentration != c }
          .sort_by(&:replicate)

        1.upto(replicates) do |r|
          expect(sample = samples.shift).to_not be_nil
          expect(sample.concentration).to eq(c)
          expect(sample.replicate).to eq(r)
        end
      end
    end

    describe "LOD purpose" do
      it "creates samples" do
        expect do
          post :create, params: { box: {
            purpose: "LOD",
            batch_uuids: { "lod" => batch.uuid },
            blinded: true
          } }
          expect(response).to redirect_to(boxes_path)
        end.to change(institution.samples, :count).by(28)

        expect(Box.last.samples.count).to eq(28)
        expect_samples(batch, concentrations: (1..8).map{|e| 10**e}, replicates: 3)
        expect_samples(batch, concentrations: [0], replicates: 4)
      end

      it "requires one batch" do
        expect do
          post :create, params: { box: {
            purpose: "LOD",
            batch_uuids: { "lod" => "" },
          } }
          expect(response).to have_http_status(:unprocessable_entity)
        end.to change(institution.samples, :count).by(0)
      end
    end

    describe "Variants purpose" do
      it "creates samples" do
        batches = Batch.make!(6, institution: institution)
        batch_uuids = Hash[batches.map.with_index { |b, i| ["variant_#{i}", b.uuid] }]

        expect do
          post :create, params: { box: {
            purpose: "Variants",
            batch_uuids: batch_uuids,
            blinded: true,
          } }
          expect(response).to redirect_to(boxes_path)
        end.to change(institution.samples, :count).by(54)

        expect(Box.last.samples.count).to eq(54)
        batches.each do |b|
          expect_samples(b, concentrations: [1, 4, 8].map{|e| 10**e}, replicates: 3)
        end
      end

      it "requires at least 2 variant batches" do
        expect do
          post :create, params: { box: {
            purpose: "Variants",
            batch_uuids: { "variant_1" => batch.uuid },
          } }
          expect(response).to have_http_status(:unprocessable_entity)
        end.to change(institution.samples, :count).by(0)
      end

      it "creates samples from 2 batches" do
        other_batch = Batch.make!(institution: institution)

        expect do
          post :create, params: { box: {
            purpose: "Variants",
            batch_uuids: {
              "variant_4" => batch.uuid,
              "variant_2" => other_batch.uuid,
            },
            blinded: true,
          } }
          expect(response).to redirect_to(boxes_path)
        end.to change(institution.samples, :count).by(18)
      end
    end

    describe "Challenge purpose" do
      it "creates samples" do
        batches = Batch.make!(6, institution: institution)
        batch_uuids = { "virus" => batch.uuid }
        batches.each_with_index { |b, i| batch_uuids["distractor_#{i + 1}"] = b.uuid }

        expect do
          post :create, params: { box: {
            purpose: "Challenge",
            batch_uuids: batch_uuids,
            blinded: true,
          } }
          expect(response).to redirect_to(boxes_path)
        end.to change(institution.samples, :count).by(108)

        expect(Box.last.samples.count).to eq(108)

        # virus batch
        expect_samples(batch, concentrations: [1, 4, 8].map{|e| 10**e}, replicates: 18)

        # distractor batches
        batches.each do |b|
          expect_samples(b, concentrations: [1, 4, 8].map{|e| 10**e}, replicates: 3)
        end
      end

      it "requires a virus batch" do
        distractor = Batch.make!(institution: institution)

        expect do
          post :create, params: { box: {
            purpose: "Challenge",
            batch_uuids: { "1" => distractor.uuid },
          } }
          expect(response).to have_http_status(:unprocessable_entity)
        end.to change(institution.samples, :count).by(0)
      end

      it "requires at least 1 distractor batches" do
        expect do
          post :create, params: { box: {
            purpose: "Challenge",
            batch_uuids: { "virus" => batch.uuid },
          } }
          expect(response).to have_http_status(:unprocessable_entity)
        end.to change(institution.samples, :count).by(0)
      end

      it "creates samples from 1 virus batch and 1 distractor batches" do
        distractor = Batch.make!(institution: institution)

        expect do
          post :create, params: { box: {
            purpose: "Challenge",
            batch_uuids: {
              "virus" => batch.uuid,
              "distractor_4" => distractor.uuid,
            },
            blinded: true
          } }
          expect(response).to redirect_to(boxes_path)
        end.to change(institution.samples, :count).by(63)
      end
    end

    describe "Other purpose" do
      it "creates with samples" do
        samples = Sample.make! 2, :filled, institution: institution, specimen_role: "b"

        expect do
          expect do
            post :create, params: { box: {
              purpose: "Other",
              sample_uuids: {
                "sample_0" => samples[0].uuid,
                "sample_1" => samples[1].uuid,
              },
              blinded: true,
            } }
            expect(response).to redirect_to(boxes_path)
          end.to change(institution.samples, :count).by(0)
        end.to change(institution.boxes, :count).by(1)

        expect(Box.last.samples.map(&:uuid).sort).to eq(samples.map(&:uuid).sort)
      end

      it "won't create with QC samples" do
        samples = [
          Sample.make!(:filled, institution: institution, specimen_role: "b"),
          Sample.make!(:filled, institution: institution, specimen_role: "q"),
        ]

        expect do
          expect do
            post :create, params: { box: {
              purpose: "Other",
              sample_uuids: {
                "sample_0" => samples[0].uuid,
                "sample_1" => samples[1].uuid,
              }
            } }
            expect(response).to have_http_status(:unprocessable_entity)
          end.to change(institution.samples, :count).by(0)
        end.to change(institution.boxes, :count).by(0)
      end

      it "requires at least 1 sample" do
        expect do
          expect do
            post :create, params: { box: { purpose: "Other", sample_uuids: {} } }
            expect(response).to have_http_status(:unprocessable_entity)
          end.to change(institution.samples, :count).by(0)
        end.to change(institution.boxes, :count).by(0)
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
