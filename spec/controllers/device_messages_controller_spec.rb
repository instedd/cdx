require 'spec_helper'

describe DeviceMessagesController do

  let!(:institution) { Institution.make }
  let!(:other_institution) { Institution.make }
  let!(:site) { Site.make institution: institution }
  let!(:device) { Device.make institution: institution, site: site }
  let!(:device_message) { DeviceMessage.make device: device, site: site}

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
