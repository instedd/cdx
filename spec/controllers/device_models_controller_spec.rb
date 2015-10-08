require 'spec_helper'
require 'policy_spec_helper'

describe DeviceModelsController do

  let!(:user)         { User.make }
  let!(:institution)  { user.institutions.make }
  let!(:device_model) { institution.device_models.make(:unpublished) }

  let!(:user2)         { User.make }
  let!(:institution2)  { user2.institutions.make }
  let!(:device_model2) { institution2.device_models.make(:unpublished) }
  let!(:device_model3) { institution2.device_models.make(:unpublished) }

  before(:each) {sign_in user}

  let(:manifest_attributes) do
    {"definition" => %{{
      "metadata": {
        "version" : "1.0.0",
        "api_version" : "#{Manifest::CURRENT_VERSION}",
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
  end


  context "index" do

    it "should list institution device models" do
      get :index
      expect(assigns(:device_models)).to contain_exactly(device_model)
      expect(response).to be_success
    end

    it "should list authorised device models" do
      grant user2, user, [device_model2], [READ_DEVICE_MODEL]

      get :index
      expect(assigns(:device_models)).to contain_exactly(device_model, device_model2)
      expect(response).to be_success
    end

  end


  context "new" do

    it "should render new page" do
      get :new
      expect(response).to be_success
      expect(assigns(:device_model)).to_not be_nil
    end

    it "should assign institution if there is only one" do
      get :new
      expect(response).to be_success
      expect(assigns(:device_model).institution).to eq(institution)
    end

  end


  context "create" do

    it "should create a device model" do
      expect {
        post :create, device_model: { name: "GX4001", institution_id: institution.id, manifest_attributes: manifest_attributes }
      }.to change(DeviceModel, :count).by(1)
      expect(response).to be_redirect
    end

    it "should not create if JSON is not valid" do
      json = {"definition" => %{ { , , } } }
      expect {
        post :create, device_model: { name: "GX4001", institution_id: institution.id, manifest_attributes: json }
      }.to change(DeviceModel, :count).by(0)
    end

    it "should not create if institution is empty" do
      expect {
        post :create, device_model: { name: "GX4001", manifest_attributes: manifest_attributes }
      }.to raise_error(ActiveRecord::RecordNotFound)
      expect(DeviceModel.count).to eq(3)
    end

    it "should not allow to create in unauthorised institution" do
      expect {
        post :create, device_model: { name: "GX4001", institution_id: institution2.id, manifest_attributes: manifest_attributes }
      }.to change(DeviceModel, :count).by(0)
      expect(response).to be_forbidden
    end

    it "should create in other institution if authorised" do
      grant user2, user, institution2, REGISTER_INSTITUTION_DEVICE_MODEL
      expect {
        post :create, device_model: { name: "GX4001", institution_id: institution2.id, manifest_attributes: manifest_attributes }
      }.to change(DeviceModel, :count).by(1)
      expect(response).to be_redirect
    end

  end


  context "edit" do

    it "should render edit page" do
      get :edit, id: device_model.id
      expect(response).to be_success
      expect(assigns(:device_model)).to eq(device_model)
    end

    it "should render edit page if authorised" do
      grant user2, user, device_model2, UPDATE_DEVICE_MODEL
      get :edit, id: device_model2.id
      expect(response).to be_success
      expect(assigns(:device_model)).to eq(device_model2)
    end

    it "should not render edit page if unauthorised" do
      get :edit, id: device_model2.id
      expect(response).to be_forbidden
    end

  end


  context "update" do

    it "should update a device model" do
      patch :update, id: device_model.id, device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes }
      expect(device_model.reload.name).to eq("NEWNAME")
      expect(device_model.reload.published_at).to be_nil
      expect(response).to be_redirect
    end

    it "should publish a device model" do
      patch :update, id: device_model.id, publish: "1", device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes }
      expect(device_model.reload.name).to eq("NEWNAME")
      expect(device_model.reload.published_at).to be_not_nil
      expect(response).to be_redirect
    end

    it "should not update a device model if unauthorised" do
      patch :update, id: device_model2.id, device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes }
      expect(device_model2.reload.name).to_not eq("NEWNAME")
      expect(device_model2.reload.published_at).to be_nil
      expect(response).to be_forbidden
    end

    it "should update a device model from another institution if authorised" do
      grant user2, user, device_model2, UPDATE_DEVICE_MODEL
      patch :update, id: device_model2.id, device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes }
      expect(device_model2.reload.name).to eq("NEWNAME")
      expect(device_model2.reload.published_at).to be_nil
      expect(response).to be_redirect
    end

    it "should not publish a device model from another institution if unauthorised" do
      grant user2, user, device_model2, [UPDATE_DEVICE_MODEL]
      patch :update, id: device_model2.id, publish: "1", device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes }
      expect(device_model2.reload.published_at).to be_nil
      expect(response).to be_redirect
    end

    it "should publish a device model from another institution if authorised" do
      grant user2, user, device_model2, [UPDATE_DEVICE_MODEL, PUBLISH_DEVICE_MODEL]
      patch :update, id: device_model2.id, publish: "1", device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes }
      expect(device_model2.reload.name).to eq("NEWNAME")
      expect(device_model2.reload.published_at).to be_not_nil
      expect(response).to be_redirect
    end

    it "should not allow to change institution" do
      grant user2, user, [Institution, DeviceModel], "*"
      patch :update, id: device_model.id, device_model: { name: "NEWNAME", institution_id: institution2.id, manifest_attributes: manifest_attributes }
      expect(device_model.reload.institution_id).to eq(institution.id)
      expect(response).to_not be_success
    end

  end


  context "destroy" do

    it "should delete a device model" do
      expect {
        delete :destroy, id: device_model.id
      }.to change(DeviceModel, :count).by(-1)
    end

    it "should not delete a device model if unauthorised" do
      expect {
        delete :destroy, id: device_model2.id
      }.to change(DeviceModel, :count).by(0)
    end

    it "should delete a device model from another institution if authorised" do
      grant user2, user, device_model2, DELETE_DEVICE_MODEL
      expect {
        delete :destroy, id: device_model2.id
      }.to change(DeviceModel, :count).by(-1)
    end

  end

end


