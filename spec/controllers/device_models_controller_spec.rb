require 'spec_helper'
require 'policy_spec_helper'

describe DeviceModelsController do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user, kind: "manufacturer"
    @device_model = DeviceModel.make! :unpublished, institution: @institution
    @institution1 = Institution.make! user: @user, kind: "manufacturer"
    @device_model1 = DeviceModel.make! :unpublished, institution: @institution1

    @user2 = User.make!
    @institution2 = Institution.make! user: @user2, kind: "manufacturer"
    @device_model2 = DeviceModel.make! :unpublished, institution: @institution2
    @device_model3 = DeviceModel.make! :unpublished, institution: @institution2
  end

  before(:each) {sign_in user}
  let(:default_params) { {context: institution.uuid} }

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

    it "should list all device models of selected institution for a manufacturer admin" do
      get :index
      expect(assigns(:device_models)).to match_array([device_model])
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
        post :create, params: { device_model: { name: "GX4001", manifest_attributes: manifest_attributes, supports_activation: true, support_url: "http://example.org/gx4001" } }
      }.to change(DeviceModel, :count).by(1)
      new_device_model = DeviceModel.last
      expect(new_device_model).to_not be_published
      expect(new_device_model.institution).to eq(institution)
      expect(new_device_model.supports_activation).to be_truthy
      expect(new_device_model.support_url).to eq("http://example.org/gx4001")
      expect(response).to be_redirect
    end

    it "should not create if JSON is not valid" do
      json = {"definition" => %{ { , , } } }
      expect {
        post :create, params: { device_model: { name: "GX4001", manifest_attributes: json } }
      }.to change(DeviceModel, :count).by(0)
    end

    it "should not allow to create in unauthorised institution" do
      grant user2, user, institution2, READ_INSTITUTION
      expect {
        post :create, params: { context: institution2.uuid, device_model: { name: "GX4001", manifest_attributes: manifest_attributes } }
      }.to change(DeviceModel, :count).by(0)
      expect(response).to be_forbidden
    end

    it "should create in other institution if authorised" do
      grant user2, user, institution2, READ_INSTITUTION
      grant user2, user, institution2, REGISTER_INSTITUTION_DEVICE_MODEL
      expect {
        post :create, params: { context: institution2.uuid, device_model: { name: "GX4001", manifest_attributes: manifest_attributes } }
      }.to change(DeviceModel, :count).by(1)
      expect(DeviceModel.last.institution).to eq(institution2)
      expect(response).to be_redirect
    end

    it "should publish on creation" do
      expect {
        post :create, params: { publish: "1", device_model: { name: "GX4001", manifest_attributes: manifest_attributes } }
      }.to change(DeviceModel, :count).by(1)
      expect(DeviceModel.last).to be_published
      expect(response).to be_redirect
    end

    it "should not persist published mark if validation fails" do
      json = {"definition" => %{ { , , } } }
      post :create, params: { publish: "1", device_model: { name: "GX4001", manifest_attributes: json } }
      expect(assigns(:device_model)).to_not be_published
    end

  end


  context "edit" do

    it "should render edit page" do
      get :edit, params: { id: device_model.id }
      expect(response).to be_success
      expect(assigns(:device_model)).to eq(device_model)
    end

    it "should render edit page if authorised" do
      grant user2, user, device_model2, UPDATE_DEVICE_MODEL
      get :edit, params: { id: device_model2.id }
      expect(response).to be_success
      expect(assigns(:device_model)).to eq(device_model2)
    end

    it "should not render edit page if unauthorised" do
      get :edit, params: { id: device_model2.id }
      expect(response).to be_forbidden
    end

  end


  context "update" do

    let(:published_device_model)  { DeviceModel.make! institution: institution }
    let(:published_device_model2) { DeviceModel.make! institution: institution2 }

    let(:site)  { Site.make! institution: institution }
    let(:site2) { Site.make! institution: institution2 }

    it "should update a device model" do
      patch :update, params: { id: device_model.id, device_model: { name: "NEWNAME", supports_activation: true, manifest_attributes: manifest_attributes, support_url: "http://example.org/new" } }
      expect(device_model.reload.name).to eq("NEWNAME")
      expect(device_model.supports_activation).to be_truthy
      expect(device_model.support_url).to eq("http://example.org/new")
      expect(device_model.reload).to_not be_published
      expect(response).to be_redirect
    end

    it "should publish a device model" do
      patch :update, params: { id: device_model.id, publish: "1", device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(device_model.reload.name).to eq("NEWNAME")
      expect(device_model.reload).to be_published
      expect(response).to be_redirect
    end

    it "should not update a device model if unauthorised" do
      patch :update, params: { id: device_model2.id, device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(device_model2.reload.name).to_not eq("NEWNAME")
      expect(device_model2.reload).to_not be_published
      expect(response).to be_forbidden
    end

    it "should update a device model from another institution if authorised" do
      grant user2, user, device_model2, UPDATE_DEVICE_MODEL
      patch :update, params: { id: device_model2.id, device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(device_model2.reload.name).to eq("NEWNAME")
      expect(device_model2.reload).to_not be_published
      expect(response).to be_redirect
    end

    it "should not publish a device model from another institution if unauthorised" do
      grant user2, user, device_model2, [UPDATE_DEVICE_MODEL]
      patch :update, params: { id: device_model2.id, publish: "1", device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(device_model2.reload).to_not be_published
      expect(response).to be_redirect
    end

    it "should publish a device model from another institution if authorised" do
      grant user2, user, device_model2, [UPDATE_DEVICE_MODEL, PUBLISH_DEVICE_MODEL]
      patch :update, params: { id: device_model2.id, publish: "1", device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(device_model2.reload.name).to eq("NEWNAME")
      expect(device_model2.reload).to be_published
      expect(response).to be_redirect
    end

    it "should not allow to change institution" do
      grant user2, user, [Institution, DeviceModel], "*"
      patch :update, params: { id: device_model.id, device_model: { name: "NEWNAME", institution_id: institution2.id, manifest_attributes: manifest_attributes } }
      expect(device_model.reload.institution_id).to eq(institution.id)
      expect(response).to_not be_success
    end

    it "should unpublish a device model" do
      patch :update, params: { id: published_device_model.id, unpublish: "1", device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(published_device_model.reload.name).to eq("NEWNAME")
      expect(published_device_model.reload).to_not be_published
      expect(response).to be_redirect
    end

    it "should unpublish a device model if authorised" do
      grant nil, user, published_device_model2, [UPDATE_DEVICE_MODEL, PUBLISH_DEVICE_MODEL]
      patch :update, params: { id: published_device_model2.id, unpublish: "1", device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(published_device_model2.reload).to_not be_published
    end

    it "should not unpublish a device model if unauthorised" do
      grant nil, user, published_device_model2, [UPDATE_DEVICE_MODEL]
      patch :update, params: { id: published_device_model2.id, unpublish: "1", device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(published_device_model2.reload).to be_published
    end

    it "should unpublish a device model if it has devices in the same institution" do
      Device.make!(site: site, device_model: published_device_model)
      patch :update, params: { id: published_device_model.id, unpublish: "1", device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(published_device_model.reload).to_not be_published
    end

    it "should not unpublish a device model if it has devices outside the institution" do
      Device.make!(site: site2, device_model: published_device_model)
      patch :update, params: { id: published_device_model.id, unpublish: "1", device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(published_device_model.reload).to be_published
    end

    it "should update a published device model" do
      patch :update, params: { id: published_device_model.id, device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(published_device_model.reload.name).to eq("NEWNAME")
      expect(published_device_model.reload).to be_published
      expect(response).to be_redirect
    end

    it "should not update a published device model if unauthorised" do
      grant user2, user, DeviceModel, UPDATE_DEVICE_MODEL
      patch :update, params: { id: published_device_model2.id, device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(published_device_model2.reload.name).to_not eq("NEWNAME")
      expect(published_device_model2.reload).to be_published
    end

    it "should update a published device model from another institution if authorised" do
      grant user2, user, DeviceModel, [UPDATE_DEVICE_MODEL, PUBLISH_DEVICE_MODEL]
      patch :update, params: { id: published_device_model2.id, device_model: { name: "NEWNAME", manifest_attributes: manifest_attributes } }
      expect(published_device_model2.reload.name).to eq("NEWNAME")
      expect(published_device_model2.reload).to be_published
    end

  end


  context "publish" do

    let(:published_device_model)  { DeviceModel.make! institution: institution }
    let(:published_device_model2) { DeviceModel.make! institution: institution2 }

    let(:site)  { Site.make! institution: institution }
    let(:site2) { Site.make! institution: institution2 }

    it "should publish a device model" do
      put :publish, params: { id: device_model.id, publish: "1" }
      expect(device_model.reload).to be_published
      expect(response).to be_redirect
    end

    it "should not publish a device model from another institution if unauthorised" do
      grant user2, user, device_model2, [UPDATE_DEVICE_MODEL]
      put :publish, params: { id: device_model2.id, publish: "1" }
      expect(device_model2.reload).to_not be_published
    end

    it "should publish a device model from another institution if authorised" do
      grant user2, user, device_model2, [UPDATE_DEVICE_MODEL, PUBLISH_DEVICE_MODEL]
      put :publish, params: { id: device_model2.id, publish: "1" }
      expect(device_model2.reload).to be_published
      expect(response).to be_redirect
    end

    it "should unpublish a device model" do
      put :publish, params: { id: published_device_model.id, unpublish: "1" }
      expect(published_device_model.reload).to_not be_published
      expect(response).to be_redirect
    end

    it "should unpublish a device model if authorised" do
      grant nil, user, published_device_model2, [UPDATE_DEVICE_MODEL, PUBLISH_DEVICE_MODEL]
      put :publish, params: { id: published_device_model2.id, unpublish: "1" }
      expect(published_device_model2.reload).to_not be_published
    end

    it "should not unpublish a device model if unauthorised" do
      grant nil, user, published_device_model2, [UPDATE_DEVICE_MODEL]
      put :publish, params: { id: published_device_model2.id, unpublish: "1" }
      expect(published_device_model2.reload).to be_published
    end

    it "should unpublish a device model if it has devices in the same institution" do
      Device.make!(site: site, device_model: published_device_model)
      put :publish, params: { id: published_device_model.id, unpublish: "1" }
      expect(published_device_model.reload).to_not be_published
    end

    it "should not unpublish a device model if it has devices outside the institution" do
      Device.make!(site: site2, device_model: published_device_model)
      put :publish, params: { id: published_device_model.id, unpublish: "1" }
      expect(published_device_model.reload).to be_published
    end

  end


  context "destroy" do

    let(:published_device_model)  { DeviceModel.make! institution: institution }

    it "should delete a device model" do
      expect {
        delete :destroy, params: { id: device_model.id }
      }.to change(DeviceModel, :count).by(-1)
    end

    it "should not delete a device model if unauthorised" do
      expect {
        delete :destroy, params: { id: device_model2.id }
      }.to change(DeviceModel, :count).by(0)
    end

    it "should not delete a device model if published" do
      published_device_model
      expect {
        delete :destroy, params: { id: published_device_model.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
      expect(published_device_model.reload.id).to be_not_nil
    end

    it "should delete a device model from another institution if authorised" do
      grant user2, user, device_model2, DELETE_DEVICE_MODEL
      expect {
        delete :destroy, params: { id: device_model2.id }
      }.to change(DeviceModel, :count).by(-1)
    end

  end

end
