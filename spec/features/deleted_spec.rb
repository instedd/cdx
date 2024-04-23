require 'spec_helper'
require 'policy_spec_helper'

describe "deleted entities should be accessible", elasticsearch: true do
  let(:institution) { Institution.make! }
  let(:user) { institution.user }
  let(:site) { Site.make! institution: institution }
  let!(:device_spec_helper) { DeviceSpecHelper.new 'genoscan' }
  let!(:device) { device_spec_helper.make! site: site }

  before(:each) {
    device_spec_helper.import_sample_csv device, 'genoscan_sample.csv'
    device.destroy
    site.destroy

    sign_in(user)
  }

  context "from test of deleted site and device" do
    before(:each) {
      goto_page TestResultsPage do |page|
        page.table.items.first.click
        expect(page).to be_success
      end
    }

    it "should be able to access site" do
      skip "sometimes fails on github actions" if ENV["CI"]

      click_link site.name

      expect_page SiteEditPage do |page|
        expect(page.shows_deleted?).to be_truthy
      end
    end

    it "should be able to access device" do
      skip "sometimes fails on github actions" if ENV["CI"]

      click_link device.name

      expect_page DevicePage do |page|
        expect(page.shows_deleted?).to be_truthy
      end
    end
  end


end
