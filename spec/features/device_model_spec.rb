require 'spec_helper'

describe "device model" do
  let(:user) { Institution.make(:manufacturer).user }
  before(:each) { sign_in(user) }

  pending "can create model and access to it's details" do
    # pending due to https://github.com/ariya/phantomjs/issues/12506

    goto_page NewDeviceModelPage do |page|
      page.name.set "MyModel"
      page.support_url.set "example.org/support"
      page.manifest.attach "db/seeds/manifests/genoscan_manifest.json"
      page.submit
    end

    expect_page DeviceModelsPage do |page|
      page.table.items.first.tap do |item|
        expect(item).to have_content("MyModel")
        item.click
      end
    end

    expect_page DeviceModelPage do |page|
      expect(page).to have_content("MyModel")
    end
  end
end
