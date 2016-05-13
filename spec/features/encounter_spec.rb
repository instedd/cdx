require 'spec_helper'
require 'policy_spec_helper'

describe "create encounter" do
  let(:device) { Device.make }
  let(:institution) { device.institution }
  let(:site) { institution.sites.first }
  let(:user) { device.institution.user }

  before(:each) {
    user.update_attribute(:last_navigation_context, site.uuid)
    sign_in(user)
  }

  it "should use current context site as default" do
    goto_page NewEncounterPage do |page|
      page.submit
    end

    expect_page ShowEncounterPage do |page|
      expect(page.encounter.site).to eq(site)
    end
  end

  it "should work when context is institution with single site" do
    user.update_attribute(:last_navigation_context, institution.uuid)

    goto_page NewEncounterPage do |page|
      page.submit
    end

    expect_page ShowEncounterPage do |page|
      expect(page.encounter.site).to eq(site)
    end
  end

  it "should obly user to choose site when context is institution with multiple sites", testrail: 432 do
    other_site = institution.sites.make
    user.update_attribute(:last_navigation_context, institution.uuid)

    goto_page NewEncounterPage do |page|
      expect(page).to have_no_primary
      page.site.set other_site.name
      expect(page).to have_primary
      page.submit
    end

    expect_page ShowEncounterPage do |page|
      expect(page.encounter.site).to eq(other_site)
    end
  end

  context "within not owned institution" do
    let(:other_institution) { Institution.make }
    let(:site1) { other_institution.sites.make }
    let(:site2) { other_institution.sites.make }
    let(:site3) { other_institution.sites.make }

    before(:each) {
      grant other_institution.user, user, other_institution, READ_INSTITUTION
      user.update_attribute(:last_navigation_context, other_institution.uuid)
    }

    it "should load empty new encounter when user has no create encounter permission for any site" do
      goto_page NewEncounterPage do |page|
        expect(page).to have_no_primary
      end
    end

    it "should not ask for site if user sees single site for institution" do
      grant other_institution.user, user, site1, READ_SITE
      grant other_institution.user, user, site1, CREATE_SITE_ENCOUNTER
      grant other_institution.user, user, {encounter: site1}, READ_ENCOUNTER

      goto_page NewEncounterPage do |page|
        page.submit
      end

      expect_page ShowEncounterPage do |page|
        expect(page.encounter.site).to eq(site1)
      end
    end

    it "should only show sites with create encounter permission of context institution" do
      grant other_institution.user, user, site1, READ_SITE
      grant other_institution.user, user, site1, CREATE_SITE_ENCOUNTER
      grant other_institution.user, user, {encounter: site1}, READ_ENCOUNTER

      grant other_institution.user, user, site2, READ_SITE
      grant other_institution.user, user, site2, CREATE_SITE_ENCOUNTER
      grant other_institution.user, user, {encounter: site2}, READ_ENCOUNTER

      goto_page NewEncounterPage do |page|
        expect(page.site.options).to match([site1.name, site2.name])
        page.site.set site1.name
        page.submit
      end

      expect_page ShowEncounterPage do |page|
        expect(page.encounter.site).to eq(site1)
      end
    end
  end

  context "adding test from other encounter" do
    it "should leave one encounter"
    it "should use encounter's diagnosis for merging"
    it "should merge patient data"
  end

  context "adding test from many others encounter" do
    it "should leave one encounter"
  end

  it "should be able to create fresh encounter with existing patient", testrail: 1192 do
    patient = institution.patients.make name: Faker::Name.name, site: site

    goto_page NewFreshEncounterPage do |page|
      page.patient.type_and_select patient.name
      page.add_sample.click
      page.add_sample.click

      page.submit
    end

    expect_page ShowEncounterPage do |page|
      expect(page.encounter.patient).to eq(patient)
      expect(page.encounter.samples.count).to eq(2)
      expect(page.encounter.test_results.count).to eq(0)
    end
  end

  it "should be able to create fresh encounter with new patient", testrail: 1193 do
    goto_page NewFreshEncounterPage do |page|
      page.new_patient.click
    end

    expect_page NewPatientPage do |page|
      page.name.set "John Doe"
      page.patient_id.set "1001"
      page.submit
    end

    expect_page NewFreshEncounterPage do |page|
      page.add_sample.click
      page.add_sample.click
      page.submit
    end

    expect_page ShowEncounterPage do |page|
      expect(page.encounter.patient.name).to eq("John Doe")
      expect(page.encounter.patient.entity_id).to eq("1001")
      expect(page.encounter.samples.count).to eq(2)
      expect(page.encounter.test_results.count).to eq(0)
    end
  end
end
