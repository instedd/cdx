require 'spec_helper'
require 'policy_spec_helper'

describe "device" do
  context "create" do
    let(:user) { Institution.make.user }
    let(:other_institution) { Institution.make }

    before(:each) {
      grant other_institution.user, user, other_institution, [READ_INSTITUTION]
      sign_in(user)
    }

    it "can access if allowed" do
      grant other_institution.user, user, Device, [READ_DEVICE]
      grant other_institution.user, user, other_institution, [REGISTER_INSTITUTION_DEVICE]

      goto_page NewDevicePage, query: { context: other_institution.uuid } do |page|
        expect(page.content).to have_content(other_institution.name)
        expect(page).to be_success
      end
    end

    it "get's forbidden if not allowed" do
      grant other_institution.user, user, Device, [READ_DEVICE]

      goto_page NewDevicePage, query: { context: other_institution.uuid } do |page|
        expect(page).to be_forbidden
      end
    end
  end

  context "creating a device by a lab user (fix #830, #677)" do
    let!(:device_spec_helper) { DeviceSpecHelper.new 'genoscan' }
    let(:user) { Institution.make.user }
    let(:other_institution) { Institution.make }

    before(:each) {
      grant other_institution.user, user, other_institution, [READ_INSTITUTION]
      grant other_institution.user, user, other_institution, [REGISTER_INSTITUTION_DEVICE]
      grant other_institution.user, user, {site: other_institution}, ASSIGN_DEVICE_SITE
      grant other_institution.user, user, {device: other_institution}, [UPDATE_DEVICE]
      sign_in(user)
    }

    def create_device
      goto_page NewDevicePage, query: { context: other_institution.uuid } do |page|
        page.device_model.set "genoscan"
        page.name.set "MyDevice"
        page.serial_number.set "1234"
        yield page if block_given?
        page.submit
      end


      expect_page DeviceSetupPage do |page|
        return page.device
      end
    end

    context "with a single site" do
      let!(:site) { other_institution.sites.make }

      it "should assign the device to the sole site" do
        expect(create_device.site).to eq(site)
      end
    end

    context "with multiple sites" do
      let!(:site) { other_institution.sites.make }
      let!(:site2) { other_institution.sites.make }

      it "should assign the device to no site" do
        expect(create_device.site).to be_nil
      end

      it "should be able to specify a site", testrail: 1185 do
        device = create_device do |page|
          page.site.set site2.name
        end

        expect(device.site).to eq(site2)
      end
    end
  end


  context "activation" do
    context "manufacturer" do
      let(:user) { Institution.make(:manufacturer).user }
      before(:each) { sign_in(user) }

      it "can create model with activation and device get a token" do
        goto_page NewDeviceModelPage do |page|
          page.name.set "MyModel"
          page.support_url.set "example.org/support"
          page.supports_activation.set true
          page.manifest.attach "db/seeds/manifests/genoscan_manifest.json"
          page.submit
        end

        goto_page NewDevicePage do |page|
          page.device_model.set "MyModel"
          page.name.set "MyDevice"
          page.serial_number.set "1234"
          page.submit
        end

        expect_page DeviceSetupPage do |page|
          expect(page).to have_content("MyDevice")
          expect(page).to have_content("MyModel")
          expect(page).to have_content("Activation token")
          expect(page).to_not have_content("Secret Key")
        end
      end

      it "can create model without activation and device show a secret ket only once" do
        goto_page NewDeviceModelPage do |page|
          page.name.set "MyModel"
          page.support_url.set "example.org/support"
          page.supports_activation.set false
          page.manifest.attach "db/seeds/manifests/genoscan_manifest.json"
          page.submit
        end

        goto_page NewDevicePage do |page|
          page.device_model.set "MyModel"
          page.name.set "MyDevice"
          page.serial_number.set "1234"
          page.submit
        end

        expect_page DeviceSetupPage do |page|
          expect(page).to have_content("MyDevice")
          expect(page).to have_content("MyModel")
          expect(page).to_not have_content("Activation token")
          expect(page).to have_content("Secret Key")
          expect(page).to_not have_content("Regenerate Key")
          expect(page).to have_content("This is the last time you will be able to view this key.")
        end

        visit current_path
        expect_page DeviceSetupPage do |page|
          expect(page).to have_content("Secret Key")
          expect(page).to have_content("Regenerate Key")
          expect(page).to_not have_content("This is the last time you will be able to view this key.")
        end
      end
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
        page.tabs_content.explore_tests.click
      end

      expect(page).to have_content '2 tests'
    end
  end

  context "device with test" do
    let(:institution) { Institution.make }
    let(:user) { institution.user }
    let(:site) { institution.sites.make }

    let(:device_spec_helper) { DeviceSpecHelper.new 'genoscan' }
    let(:device) { device_spec_helper.make site: site }

    before(:each) {
      device_spec_helper.import_sample_csv device, 'genoscan_sample.csv'
      sign_in(user)
    }

    context "when deleted" do
      before(:each) {
        goto_page DevicePage, id: device.id do |page|
          page.edit.click
        end

        expect_page DeviceEditPage do |page|
          page.delete.click
          page.confirmation.delete.click
        end
      }

      it "test details can be views if device is deleted", testrail: 1184 do
        goto_page TestResultsPage do |page|
          page.table.items.first.click
          expect(page).to be_success
        end
      end
    end
  end

  context "moving site" do
    let(:institution) { Institution.make }
    let(:user) { institution.user }
    let!(:old_parent) { institution.sites.make }
    let!(:new_parent) { institution.sites.make }
    let(:site) { Site.make :child, parent: old_parent }

    let!(:device_spec_helper) { DeviceSpecHelper.new 'genoscan' }
    let!(:device) { device_spec_helper.make site: site }

    before(:each) {
      device_spec_helper.import_sample_csv device, 'genoscan_sample.csv'
      expect(TestResult.count).to eq(13)
      sign_in(user)
    }

    it "can process same message payload successfully after moving" do
      goto_page SiteEditPage, site_id: site.id, query: { context: institution.uuid } do |page|
        page.parent_site.set new_parent.name
        page.submit
      end

      site.reload
      expect(site).to be_deleted
      new_site = Site.last
      expect(new_site.parent).to eq(new_parent)

      device_spec_helper.import_sample_csv device, 'genoscan_sample.csv'

      expect(Sample.count).to eq(10)
      expect(SampleIdentifier.count).to eq(10)
      expect(TestResult.count).to eq(26)
    end
  end
end
