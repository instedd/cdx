require 'spec_helper'

describe "setup instructions of device" do
  let(:device_model) { DeviceModel.make support_url: "http://example.org/support/url" }
  let(:device) { Device.make device_model: device_model }
  let(:user) { device.institution.user }

  before(:each) {
    sign_in(user)
  }

  it "shows online support_url in setup tab for activated device" do
    DeviceMessage.make device: device

    expect(device).to be_activated

    goto_page DevicePage, id: device.id do |page|
      page.tab_header.setup.click
      page.open_view_instructions do |modal|
        modal.online_support.click
      end
    end

    expect(current_url).to eq(device_model.support_url)
  end

  it "shows online support_url directly for non activated device" do
    expect(device).to_not be_activated

    goto_page DevicePage, id: device.id

    expect_page DeviceSetupPage do |page|
      page.open_view_instructions do |modal|
        modal.online_support.click
      end
    end

    expect(current_url).to eq(device_model.support_url)
  end
end
