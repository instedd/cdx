require 'spec_helper'
require 'policy_spec_helper'

describe "Patients", elasticsearch: true do
  let(:institution) { Institution.make }
 
  let(:site) { institution.sites.make }

  let!(:device_spec_helper) { DeviceSpecHelper.new 'genoscan' }
  let!(:device) { device_spec_helper.make site: site }

  let!(:user) { institution.user }
  
  context "without name" do
    before(:each) {
      device_spec_helper.import_sample_csv device, 'genoscan_sample.csv'
      sign_in(user)
    }

    it "should display 'Unknown name' in test result and in patient page", testrail: 1189 do
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

  context "filters" do
    let!(:foo_patient) { Patient.make(institution: institution, core_fields: {"gender" => "male"}, custom_fields: {"custom" => "patient value"}, is_phantom: false, plain_sensitive_data: {"name": "Doe"}) }
    let!(:bar_patient) { Patient.make(institution: institution, core_fields: {"gender" => "male"}, custom_fields: {"custom" => "patient value"}, is_phantom: false, plain_sensitive_data: {"name": "Lane"}) }

    before(:each) {
      sign_in(user)
    }

    it "should filter patients by name" do
      goto_page PatientPage do |page|

        within patient_filter do
          fill_in  "name", :with => foo_patient.name
        end

        expect(page).to have_content(foo_patient.id)
        expect(page).to_not have_content(bar_patient.id)
      end
    end

  end

end
