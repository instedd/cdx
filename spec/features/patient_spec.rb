require 'spec_helper'
require 'policy_spec_helper'

describe "Patients", elasticsearch: true do
  let(:institution) { Institution.make! }
  let(:user) { institution.user }
  let(:site) { Site.make! institution: institution }

  let!(:device_spec_helper) { DeviceSpecHelper.new 'genoscan' }
  let!(:device) { device_spec_helper.make! site: site }

  context "without name" do
    before(:each) {
      device_spec_helper.import_sample_csv device, 'genoscan_sample.csv'
      sign_in(user)
    }

    it "should display 'Unknown name' in test result and in patient page" do
      goto_page TestResultsPage do |page|
        page.table.items[6].click
      end

      click_link "(Unknown name)"

      expect_page PatientPage do |page|
        expect(page).to have_content("(Unknown name)")
        expect(page).to be_success
      end
    end
  end
end
