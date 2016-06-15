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

    it "should filter patients by name", testrail: 387 do
      goto_page PatientPage do |page|

        page.update_filters do
          fill_in  "name", :with => foo_patient.name
        end

        expect(page).to have_content(foo_patient.id)
        expect(page).to_not have_content(bar_patient.id)
      end
    end

    it "should filter patients by id", testrail: 385 do
      goto_page PatientPage do |page|

        page.update_filters do
          fill_in  "name", :with => foo_patient.id
        end

        expect(page).to have_content(foo_patient.name)
        expect(page).to_not have_content(bar_patient.name)
      end
    end

  end

  context "patient view" do
    let!(:foo_patient) { Patient.make(institution: institution, core_fields: {"gender" => "male"}, custom_fields: {"custom" => "patient value"}, is_phantom: false, plain_sensitive_data: {"name": "Doe"}) }
    
    before(:each) {
      sign_in(user)
    }

    it "should create patient", testrail: 389 do
      goto_page PatientsPage do |page|
        click_link "Add Patient"
        fill_in  "patient[name]", :with => "Peter Durkheim"
        fill_in  "patient[entity_id]", :with => "123"
        page.submit  

        expect(page).to have_content("Peter Durkheim")
      end

    end

    it "should delete patient", testrail: 391 do
      goto_page PatientsPage do |page|
        page.table.items.first.click
        click_link "Edit" 
      end

      expect_page PatientEditPage do |page|
        page.delete.click
        page.confirmation.delete.click
      end   
    end

  end

end
