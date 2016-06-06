require 'spec_helper'
require 'policy_spec_helper'

describe "tests", elasticsearch: true do 
  let!(:institution) { Institution.make }
  let!(:user) { institution.user }
  let!(:site) { institution.sites.make }
  let!(:device_spec_helper) { DeviceSpecHelper.new 'genoscan' }
  let!(:device) { device_spec_helper.make site: site }
  
  context "filters" do   
    before(:each) {
      device_spec_helper.import_sample_csv device, 'genoscan_sample.csv'
      sign_in(user)
    }

    it "should filter tests by sample id", testrail: 441 do
      goto_page TestResultsPage do |page|
        
        expect(page).to have_content("1")

        page.submit 
        page.update_filters do
          fill_in  "sample.id", :with => "1"
        end

        expect(page).to have_content("1")
        expect(page).to_not have_content("4")
      end
    end
  end

end
