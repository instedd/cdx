require 'spec_helper'

describe Api::MessagesController, elasticsearch: true, validate_manifest: false do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
  end

  let(:device) { Device.make! institution: institution }
  let(:data)  {Oj.dump test:{assays: [result: :positive]} }

  context "Authentication" do

    def assert_message_created
      message = DeviceMessage.first
      expect(message.device_id).to eq(device.id)
      expect(message.raw_data).not_to eq(data)
      expect(message.plain_text_data).to eq(data)
    end

    def assert_nothing_created
      expect(DeviceMessage.count).to eq(0)
    end

    it "should create message authenticating via web" do
      sign_in user
      response = post :create, body: data, params: { device_id: device.uuid }
      expect(response.status).to eq(200)
      assert_message_created
    end

    it "should fail without authentication" do
      response = post :create, body: data, params: { device_id: device.uuid }
      expect(response).not_to be_ok
      assert_nothing_created
    end

    it "should create message authenticating with basic auth" do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('', device.plain_secret_key)
      response = post :create, body: data, params: { device_id: device.uuid }
      expect(response.status).to eq(200)
      assert_message_created
    end

    it "should create message authenticating via secret key" do
      device.set_key
      device.save!
      response = post :create, body: data, params: { device_id: device.uuid, authentication_token: device.plain_secret_key }
      expect(response.status).to eq(200)
      assert_message_created
    end

    it "should create message authenticating via secret key when signed in" do
      sign_in user
      response = post :create, body: data, params: { device_id: device.uuid, authentication_token: device.plain_secret_key }
      expect(response.status).to eq(200)
      assert_message_created
    end

    it "should fail auth if secret key is incorrect" do
      response = post :create, body: data, params: { device_id: device.uuid, authentication_token: "WRONG" }
      expect(response).not_to be_ok
      assert_nothing_created
    end

    it "should fail auth if secret key is incorrect even if signed in" do
      sign_in user
      response = post :create, body: data, params: { device_id: device.uuid, authentication_token: "WRONG" }
      expect(response).not_to be_ok
      assert_nothing_created
    end

  end
end
