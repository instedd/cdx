require 'spec_helper'

describe DeviceCommandsController do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
    @device = Device.make! institution: @institution
  end

  before(:each) do
    device.set_key_for_activation_token
    @plain_secret_key = device.plain_secret_key
    device.save!
  end

  describe "index" do
    it "lists" do
      command = device.device_commands.create! name: "some_name", command: %({"args": [1, 2, 3]})

      get :index, params: { device_id: device.uuid, key: @plain_secret_key }

      expect(JSON.parse(response.body)).to eq([{"id" => command.id, "name" => "some_name", "args" => [1, 2, 3]}])
    end

    it "returns forbidden if wrong key" do
      get :index, params: { device_id: device.uuid, key: "#{@plain_secret_key}..." }
      expect(response).to be_forbidden
    end
  end

  describe "reply" do
    it "send_logs" do
      command = device.request_client_logs

      post :reply, body: "some log content", params: { device_id: device.uuid, key: @plain_secret_key, id: command.id }

      expect(device.device_commands.count).to eq(0)

      logs = device.device_logs.all
      expect(logs.count).to eq(1)
      expect(logs[0].message).to eq("some log content")
    end

    it "returns forbidden if wrong key" do
      command = device.request_client_logs
      post :reply, body: "some log content", params: { device_id: device.uuid, key: "#{@plain_secret_key}...", id: command.id }
      expect(response).to be_forbidden
    end
  end
end
