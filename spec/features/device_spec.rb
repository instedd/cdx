require 'spec_helper'

describe "device" do
  context "activation" do
    context "manufacturer" do
      let(:user) { Institution.make(:manufacturer).user }
      before(:each) { sign_in(user) }

      pending "can create model with activation and device get a token" do
        # pending due to https://github.com/ariya/phantomjs/issues/12506

        goto_page NewDeviceModelPage do |page|
          page.name.set "MyModel"
          page.support_url.set "example.org/support"
          page.supports_activation.set true
          page.manifest.attach "db/seeds/manifests/genoscan_manifest.json"

          # page.submit
        end

        # TBD
      end

      it "can create model without activation and device show a secret ket only once"
    end
  end

  context "setup instructions" do
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
end
