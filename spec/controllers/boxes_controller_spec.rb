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
      expect(response).to be_success
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
        expect(response).to be_success
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

  describe "new" do
    it "should be accessible to institution owner" do
      get :new
      expect(response).to be_success
    end

    it "should be allowed if can create" do
      grant user, other_user, institution, CREATE_INSTITUTION_BOX
      sign_in other_user

      get :new
      expect(response).to be_success
    end

    it "shouldn't be allowed if can't create" do
      sign_in other_user

      get :new
      expect(response).to be_forbidden
    end
  end

  describe "edit" do
    it "should be accessible to institution owner" do
      get :edit, params: { id: box.id }
      expect(response).to be_success

      expect(assigns(:can_update)).to eq(false)
      expect(assigns(:can_delete)).to eq(true)
    end

    it "should be allowed if can read" do
      grant user, other_user, box, READ_BOX
      sign_in other_user

      get :edit, params: { id: box.id }
      expect(response).to be_success

      expect(assigns(:can_update)).to eq(false)
      expect(assigns(:can_delete)).to eq(false)
    end

    it "should be allowed if can update" do
      grant user, other_user, box, READ_BOX
      grant user, other_user, box, UPDATE_BOX
      sign_in other_user

      get :edit, params: { id: box.id }
      expect(response).to be_success

      expect(assigns(:can_update)).to eq(false)
      expect(assigns(:can_delete)).to eq(false)
    end

    it "should be allowed if can update and delete" do
      grant user, other_user, box, READ_BOX
      grant user, other_user, box, UPDATE_BOX
      grant user, other_user, box, DELETE_BOX
      sign_in other_user

      get :edit, params: { id: box.id }
      expect(response).to be_success

      expect(assigns(:can_update)).to eq(false)
      expect(assigns(:can_delete)).to eq(true)
    end

    it "shouldn't be allowed if can't read" do
      sign_in other_user

      get :edit, params: { id: box.id }
      expect(response).to be_forbidden
    end
  end

  describe "create" do
    let :batch do
      Batch.make!(institution: institution)
    end

    let :box_plan do
      {
        purpose: "LOD",
        batch_uuids: [batch.uuid],
      }
    end

    it "should create box in context institution" do
      expect do
        post :create, params: { box: box_plan }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(1)

      box = assigns(:box).reload
      expect(box.uuid).to_not be_nil
      expect(box.institution_id).to eq institution.id
    end

    it "should create box in context site" do
      default_params[:context] = site.uuid

      expect do
        post :create, params: { box: box_plan }
        expect(response).to redirect_to boxes_path
      end.to change(site.boxes, :count).by(1)

      box = assigns(:box).reload
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
        expect(response).to be_forbidden
      end.to change(institution.boxes, :count).by(0)
    end

    it "creates samples for LOD purpose" do
      expect do
        post :create, params: { box: {
          purpose: "LOD",
          batch_uuids: [batch.uuid],
        } }
        expect(response).to redirect_to(boxes_path)
      end.to change(institution.samples, :count).by(24)

      expect(Box.last.samples.count).to eq(24)
      expect(batch.samples.count).to eq(24)
    end

    it "creates samples for Variants purpose" do
      batches = Batch.make!(6, institution: institution)

      expect do
        post :create, params: { box: {
          purpose: "Variants",
          batch_uuids: batches.map(&:uuid),
        } }
        expect(response).to redirect_to(boxes_path)
      end.to change(institution.samples, :count).by(54)

      expect(Box.last.samples.count).to eq(54)
      batches.each { |b| expect(b.samples.count).to eq(9) }
    end

    it "creates samples for Challenge purpose" do
      batches = Batch.make!(6, institution: institution)

      expect do
        post :create, params: { box: {
          purpose: "Challenge",
          batch_uuids: [batch.uuid, *batches.map(&:uuid)],
        } }
        expect(response).to redirect_to(boxes_path)
      end.to change(institution.samples, :count).by(108)

      expect(Box.last.samples.count).to eq(108)
      expect(batch.samples.count).to eq(54)
      batches.each { |b| expect(b.samples.count).to eq(9) }
    end
  end

  # describe "update" do
  #   let :box_plan do
  #     { placeholder: true } # TODO: set real attributes
  #   end

  #   it "should update box" do
  #     patch :update, params: { id: box.id, box: box_plan }
  #     expect(response).to redirect_to boxes_path
  #   end

  #   it "should update box if allowed" do
  #     grant user, other_user, box, UPDATE_BOX
  #     sign_in other_user

  #     patch :update, params: { id: box.id, box: box_plan }
  #     expect(response).to redirect_to boxes_path
  #   end

  #   it "should not update box if not allowed" do
  #     sign_in other_user

  #     patch :update, params: { id: box.id, box: box_plan }
  #     expect(response).to be_forbidden
  #   end
  # end

  describe "delete" do
    it "should destroy box" do
      delete :destroy, params: { id: box.id }
      expect(response).to redirect_to boxes_path
    end

    it "should destroy box if allowed" do
      grant user, other_user, box, DELETE_BOX
      sign_in other_user

      expect do
        delete :destroy, params: { id: box.id }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(-1)

      expect(box.reload.deleted_at).to_not be_nil
    end

    it "should not destroy box if not allowed" do
      sign_in other_user

      expect do
        delete :destroy, params: { id: box.id }
        expect(response).to be_forbidden
      end.to change(institution.boxes.unscoped, :count).by(0)
    end
  end
end
