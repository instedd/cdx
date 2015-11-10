require 'spec_helper'

describe "setup instructions of device" do
  let(:device_model) {
    Manifest.make.device_model.tap do |dm|
      dm.support_url = "http://example.org/support/url"
      dm.save!
    end
  }
  let(:device) { Device.make device_model: device_model }
  let(:user) { device.institution.user }

  before(:each) {
    sign_in(user)
  }

  it "shows online support_url in setup tab for activated device" do
    process

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

  it "shows tests processed by device event without name" do
    process
    process_plain test: {assays:[condition: "flu_a", result: "positive"]}

    goto_page DevicePage, id: device.id do |page|
      page.tab_header.tests.click
    end

    expect(page).to have_content '2 TESTS'
  end
end
