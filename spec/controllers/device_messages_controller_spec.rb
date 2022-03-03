require 'spec_helper'

describe DeviceMessagesController do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
    @site = Site.make! institution: @institution
    @device = Device.make! institution: @institution
    @device_message = DeviceMessage.make! device: @device, site: @site
    @other_institution = Institution.make!
  end

  it "should be downloadable by authorized users" do
    sign_in institution.user
    get :raw, id: device_message.id, context: institution.uuid
    expect(response).to be_success
  end

  it "should not be downloadable by non authorized users" do
    sign_in other_institution.user
    get :raw, id: device_message.id, context: other_institution.uuid
    expect(response).to be_forbidden
  end

  it "should be reprocessable by authorized users" do
    sign_in institution.user
    post :reprocess, id: device_message.id, context: institution.uuid
    expect(response).to redirect_to(device_messages_path)
  end

  it "should not be reprocessable by non authorized users" do
    sign_in other_institution.user
    post :reprocess, id: device_message.id, context: other_institution.uuid
    expect(response).to be_forbidden
  end

end
