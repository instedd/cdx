require 'spec_helper'
require 'policy_spec_helper'

describe DevicesController do
  let(:institution) {Institution.make}
  let(:user) {institution.user}
  let(:site) {institution.sites.make}
  let(:device_model) {DeviceModel.make}
  let(:device) {Device.make institution: institution, site: site, device_model: device_model}

  before(:each) {sign_in user}

  context "Index" do

    let!(:user2) {User.make}
    let!(:institution2) {Institution.make user: user2}
    let!(:site2) {institution2.sites.make}
    let!(:device2) {site2.devices.make}

    it "should diplay index" do
      get :index
      expect(response).to be_success
      expect(assigns(:devices)).to contain_exactly(device)
    end

    it "should display index when other user grants permissions" do
      grant user2, user, [Institution.resource_name, Device.resource_name], "*"

      get :index
      expect(response).to be_success
      expect(assigns(:devices)).to contain_exactly(device, device2)
    end

    it "should display index filtered by institution" do
      grant user2, user, [Institution.resource_name, Device.resource_name], "*"

      get :index, institution: institution2.id
      expect(response).to be_success
      expect(assigns(:devices)).to contain_exactly(device2)
    end

  end

  context "New" do

    it "renders the new page" do
      get :new
      expect(response).to be_success
    end

    it "loads published device models and from allowed institutions" do
      published = device_model
      unpublished = institution.device_models.make(:unpublished)
      other_unpublished = DeviceModel.make(:unpublished, institution: Institution.make)

      get :new
      expect(assigns(:device_models)).to contain_exactly(published, unpublished)
    end

  end

  context "Edit" do

    it "renders the edit page" do
      get :edit, id: device.id
      expect(response).to be_success
    end

    it "loads published device models and from device institution" do
      published = device_model
      unpublished = institution.device_models.make(:unpublished)
      other_user_institution = user.institutions.make
      other_unpublished = other_user_institution.device_models.make(:unpublished)

      get :edit, id: device.id
      expect(assigns(:device_models)).to contain_exactly(published, unpublished)
    end

  end

  context "Update" do

    it "device is successfully updated if name is provided" do
      d = Device.find(device.id)
      expect(d.name).not_to eq("New device")

      patch :update, {"institution_id" => institution.id, "id" => device.id, "device" => {"name" => "New device"}}

      d = Device.find(device.id)
      expect(d.name).to eq("New device")
    end

    it "device is not updated if name is not provided" do
      d = Device.find(device.id)
      expect(d.name).to eq(device.name)

      patch :update, {"institution_id" => institution.id, "id" => device.id, "device" => {"name" => ""}}

      d = Device.find(device.id)
      expect(d.name).to eq(device.name)
    end

  end

  describe "generate_activation_token" do
    before { post :generate_activation_token, {institution_id: device.institution_id, id: device.id, format: :json} }
    let(:token) { ActivationToken.find_by(device_id: device.id)  }

    it { expect(token).not_to be_nil }
    it { expect(token.device).to eq(device) }
    it { expect(token.client_id).to eq(device.uuid) }
    it { expect(token.value).not_to be_nil }
  end

  describe "request_client_logs" do
    it "creates command" do
      post :request_client_logs, id: device.id

      commands = device.device_commands.all
      expect(commands.length).to eq(1)

      command = commands[0]
      expect(command.name).to eq("send_logs")
      expect(command.command).to be_nil
    end

    it "doesn't create command twice" do
      2.times do
        post :request_client_logs, id: device.id
      end

      commands = device.device_commands.all
      expect(commands.length).to eq(1)
    end
  end
end
