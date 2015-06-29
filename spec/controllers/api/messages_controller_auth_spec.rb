require 'spec_helper'

describe Api::MessagesController, elasticsearch: true, validate_manifest: false do

  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  let(:data)  {Oj.dump test:{assays: [qualitative_result: :positive]} }

  context "Authentication" do

    def assert_message_created
      message = DeviceMessage.first
      message.device_id.should eq(device.id)
      message.raw_data.should_not eq(data)
      message.plain_text_data.should eq(data)
    end

    def assert_nothing_created
      DeviceMessage.count.should eq(0)
    end

    it "should create message authenticating via web" do
      sign_in user
      response = post :create, data, device_id: device.uuid
      response.status.should eq(200)
      assert_message_created
    end

    it "should fail without authentication" do
      response = post :create, data, device_id: device.uuid
      response.should_not be_ok
      assert_nothing_created
    end

    it "should create message authenticating with basic auth" do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('', device.plain_secret_key)
      response = post :create, data, device_id: device.uuid
      response.status.should eq(200)
      assert_message_created
    end

    it "should create message authenticating via secret key" do
      response = post :create, data, device_id: device.uuid, authentication_token: device.plain_secret_key
      response.status.should eq(200)
      assert_message_created
    end

    it "should create message authenticating via secret key when signed in" do
      sign_in user
      response = post :create, data, device_id: device.uuid, authentication_token: device.plain_secret_key
      response.status.should eq(200)
      assert_message_created
    end

    it "should fail auth if secret key is incorrect" do
      response = post :create, data, device_id: device.uuid, authentication_token: "WRONG"
      response.should_not be_ok
      assert_nothing_created
    end

    it "should fail auth if secret key is incorrect even if signed in" do
      sign_in user
      response = post :create, data, device_id: device.uuid, authentication_token: "WRONG"
      response.should_not be_ok
      assert_nothing_created
    end

  end
end
