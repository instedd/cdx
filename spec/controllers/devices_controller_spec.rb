require 'spec_helper'
require 'policy_spec_helper'

describe DevicesController do
  let!(:institution) {Institution.make}
  let!(:user) {institution.user}
  let!(:site) {institution.sites.make}
  let!(:device_model) {DeviceModel.make(institution: Institution.make(:manufacturer))}
  let!(:manifest) {Manifest.make(device_model: device_model)}
  let!(:device) {Device.make institution: institution, site: site, device_model: device_model}
  let!(:other_institution) {Institution.make user: user}
  let!(:other_site) {other_institution.sites.make}

  before(:each) {sign_in user}
  let(:default_params) { {context: institution.uuid} }

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

      get :index, context: institution2.uuid
      expect(response).to be_success
      expect(assigns(:devices)).to contain_exactly(device2)
    end

    it "should display index filtered by institution" do
      other_device = Device.make institution: other_institution

      get :index, context: other_institution.uuid
      expect(response).to be_success
      expect(assigns(:devices)).to contain_exactly(other_device)
    end

    it "should display index filtered by site" do
      other_site = Site.make institution: institution
      other_device = Device.make site: other_site

      get :index, context: other_site.uuid
      expect(response).to be_success
      expect(assigns(:devices)).to contain_exactly(other_device)
    end

    it "should display index filtered by manufacturer" do
      manufacturer = Institution.make
      device2.device_model.tap do |device_model|
        device_model.institution = manufacturer
        device_model.save!
      end
      Device.make institution: institution2

      grant user2, user, [Institution.resource_name, Device.resource_name], "*"

      get :index, context: institution2.uuid, manufacturer: manufacturer.id
      expect(response).to be_success
      expect(assigns(:devices)).to contain_exactly(device2)
    end

    it "should download CSV" do
      get :index, format: :csv
      expect(response).to be_success

      CSV.parse(response.body, headers: :first_row) do |row|
        expect(row.headers).to eq([
          "UUID", "Name", "Serial Number", "Time Zone",
          "Institution UUID", "Institution Name",
          "Model Name",
          "Manufacturer UUID", "Manufacturer Name",
          "Site UUID", "Site Name"
        ])
        expect(row.fields).to eq([
          device.uuid, device.name, device.serial_number, device.time_zone,
          device.institution.uuid, device.institution.name,
          device.device_model.name,
          device.device_model.institution.uuid, device.device_model.institution.name,
          device.site.uuid, device.site.name
        ])
      end
    end

    it "should download index CSV with current filters" do
      grant user2, user, [Institution.resource_name, Device.resource_name], "*"
      get :index, context: institution2.uuid, format: :csv
      expect(response).to be_success

      rows = CSV.parse(response.body, headers: :first_row)
      expect(rows).to have(1).item
      expect(rows.first['UUID']).to eq(device2.uuid)
    end

    it "should download all pages" do
      devices = 30.times.map { |i| Device.make institution: institution, site: site, device_model: device_model }
      get :index, format: :csv
      expect(response).to be_success

      rows = CSV.parse(response.body, headers: :first_row)
      expect(rows).to have(31).items
      expect(rows.map{|r| r['UUID']}).to match_array(devices.map(&:uuid) + [device.uuid])
    end
  end

  context "Index when devices have no sites" do

    let!(:user2) {User.make}
    let!(:institution2) {Institution.make user: user2}
    let!(:device2) {institution2.devices.make site: nil}
    let(:default_params) { {context: institution2.uuid} }

    it "should display devices without sites when selecting institution" do
      grant user2, user, Resource.all.map(&:resource_name), "*"

      get :index
      expect(response).to be_success
      expect(assigns(:devices)).to contain_exactly(device2)
    end

    it "should display manufacturers used by the devices in the current context despite manufacturer filter" do
      device_model2 = DeviceModel.make institution: Institution.make
      device2 = Device.make institution: institution, site: site, device_model: device_model2

      site3 = institution.sites.make
      device_model3 = DeviceModel.make institution: Institution.make
      device3 = Device.make institution: institution, site: site3, device_model: device_model3

      get :index, context: institution.uuid, manufacturer: device_model2.institution.id
      expect(assigns(:manufacturers)).to match_array([device_model.institution, device_model2.institution, device_model3.institution])

      get :index, context: site3.uuid
      expect(assigns(:manufacturers)).to match_array([device_model3.institution])
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

    it "loads unpublished device models only of context institution" do
      published = device_model
      unpublished = institution.device_models.make(:unpublished)
      other_institution = Institution.make(user: user)
      other_unpublished = DeviceModel.make(:unpublished, institution: other_institution)

      get :new, context: other_institution.uuid
      expect(assigns(:device_models)).to contain_exactly(published, other_unpublished)
    end

    it "loads all sites from allowed institutions in context" do
      yet_another_institution = Institution.make
      site1 = yet_another_institution.sites.make
      site2 = yet_another_institution.sites.make

      grant yet_another_institution.user, user, yet_another_institution, READ_INSTITUTION
      grant yet_another_institution.user, user, yet_another_institution, REGISTER_INSTITUTION_DEVICE
      grant yet_another_institution.user, user, site2, ASSIGN_DEVICE_SITE

      get :new, context: yet_another_institution.uuid
      expect(assigns(:sites)).to contain_exactly(site2)
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

    it "loads sites from device institution" do
      get :edit, id: device.id
      expect(assigns(:sites)).to contain_exactly(site)
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

  context "Show" do
    it "shows tests when there are device messages" do
      device.device_messages.make
      get :show, id: device.id
      expect(response).to be_success
    end

    context "without device messages" do
      it "redirects to setup if activation is not supported" do
        get :show, id: device.id
        expect(response).to redirect_to(setup_device_url(device))
      end

      context "if activation is supported" do
        before { device.device_model.update_attributes! supports_activation: true }

        it "redirects to setup if it doesn't have a secret key" do
          expect(device.secret_key_hash).to be_nil
          get :show, id: device.id
          expect(response).to redirect_to(setup_device_url(device))
        end

        context "secret key is already generated" do
          before { device.tap(&:set_key).save! }

          it "show tests if there is no activation token" do
            expect(device.activation_token).to be_nil
            get :show, id: device.id
            expect(response).to be_success
          end

          it "redirects to setup if there is activation token" do
            device.new_activation_token
            device.save!
            get :show, id: device.id
            expect(response).to redirect_to(setup_device_url(device))
          end
        end
      end
    end
  end

  context "Create" do
    it "redirects to setup with neither token or secret key when the device model doesn't support activation" do
      expect {
        post :create, device: {
          institution_id: institution.id,
          device_model_id: device_model.id,
          name: "foo",
          serial_number: "123"
        }
      }.to change(Device, :count).by(1)

      new_device = Device.last
      expect(new_device.name).to eq("foo")
      expect(new_device.serial_number).to eq("123")
      expect(new_device.secret_key_hash).to be_nil
      expect(new_device.activation_token).to be_nil
      expect(response).to redirect_to(setup_device_url(new_device))
    end

    it "redirects to setup with new activation token but no secret key when the device model supports activation" do
      device_model.supports_activation = true
      device_model.save!
      expect {
        post :create, device: {
          institution_id: institution.id,
          device_model_id: device_model.id,
          name: "foo",
          serial_number: "123"
        }
      }.to change(Device, :count).by(1)

      new_device = Device.last
      expect(new_device.name).to eq("foo")
      expect(new_device.serial_number).to eq("123")
      expect(new_device.secret_key_hash).to be_nil
      expect(new_device.activation_token).to_not be_nil
      expect(response).to redirect_to(setup_device_url(new_device))
    end

    it "doesn't crash when there's no device model (#578)" do
      post :create, device: {
        name: "foo",
        serial_number: "123"
      }

      expect(response).to be_ok
    end
  end

  describe "generate_activation_token" do
    before { post :generate_activation_token, {institution_id: device.institution_id, id: device.id, format: :json} }

    it { device.reload; expect(device.activation_token).not_to be_nil }
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

  describe "custom mappsing" do
    it "can request" do
      get :custom_mappings, device_model_id: device_model.id
      expect(response).to be_success
      expect(assigns(:device).new_record?).to be_truthy
      expect(assigns(:device).device_model).to eq(device_model)
    end
  end
end
