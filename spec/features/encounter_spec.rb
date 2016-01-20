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

  it "should obly user to choose site when context is institution with multiple sites" do
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

  it "should search sample by id substring" do
    process sample: {id: "ab111"}
    process sample: {id: "22ab2"}
    process sample: {id: "xy333"}

    goto_page NewEncounterPage do |page|
      page.open_append_sample do |modal|
        modal.perform_search "ab"
        expect(modal.results.count).to eq(2)
      end
    end
  end

  it "should search test by id substring" do
    process test: {id: "ab111"}
    process test: {id: "22ab2"}
    process test: {id: "xy333"}

    goto_page NewEncounterPage do |page|
      page.open_add_tests do |modal|
        modal.perform_search "ab"
        expect(modal.results.count).to eq(2)
      end
    end
  end

  it "should add sample to encounter on save" do
    process sample: {id: "ab111"}

    goto_page NewEncounterPage do |page|
      page.open_append_sample.search_and_select_first "ab"

      page.submit
    end

    expect_page ShowEncounterPage do |page|
      encounter = Encounter.find(page.id)
      expect(encounter.samples).to match([Sample.first])
    end
  end

  it "should add test to encounter on save" do
    process test: {id: "ab111"}

    goto_page NewEncounterPage do |page|
      page.open_add_tests.search_and_select_first "ab"

      page.submit
    end

    expect_page ShowEncounterPage do |page|
      expect(page.encounter.test_results).to match([TestResult.first])
    end
  end

  it "should create patient when adding test with information" do
    process test: {id: "ab123"}, patient: {name: "John Doe"}

    goto_page NewEncounterPage do |page|
      page.open_add_tests.search_and_select_first "ab123"

      page.submit
    end

    expect_page ShowEncounterPage do |page|
      expect(page).to have_content "John Doe"
      expect(page.encounter.patient.plain_sensitive_data["name"]).to match("John Doe")
    end
  end

  it "should merge patient information coming from different tests" do
    process test: {id: "ab123"}, patient: {name: "John Doe"}
    process test: {id: "ab456"}, patient: {gender: "male"}
    process test: {id: "ab789"}

    goto_page NewEncounterPage do |page|
      page.open_add_tests.search_and_select_first "ab123"
      page.open_add_tests.search_and_select_first "ab456" # this is not added due to multiple patients
      page.open_add_tests.search_and_select_first "ab789"

      page.submit
    end

    expect_page ShowEncounterPage do |page|
      expect(page.encounter.test_results).to have(3).items
      expect(page.encounter.patient.plain_sensitive_data["name"]).to match("John Doe")
      expect(page.encounter.patient.core_fields["gender"]).to match("male")
    end
  end

  it "should be able to change the assay result and quantity of encounter" do
    process test: {id: "a"}

    goto_page NewEncounterPage do |page|
      page.open_add_tests.search_and_select_first "a"

      page.diagnosis.assays.first.result.set "Negative"
      page.diagnosis.assays.first.quant.set 5

      page.submit
    end

    expect_page ShowEncounterPage do |page|
      expect(page).to have_content("Negative")
      expect(page).to have_content("5")

      page.submit
    end

    expect_page EditEncounterPage do |page|
      expect(page.diagnosis.assays.first.result.value).to eq("Negative")
      expect(page.diagnosis.assays.first.quant.value).to eq("5")

      page.diagnosis.assays.first.result.set "Indeterminate"
      page.diagnosis.assays.first.quant.set 3

      page.submit
    end

    expect_page ShowEncounterPage do |page|
      expect(page).to have_content("Indeterminate")
      expect(page).to have_content("3")
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

  it "adding test to existing sample should leave new test in encounter" do
    process sample: {id: "s"}

    goto_page NewEncounterPage do |page|
      page.open_append_sample.search_and_select_first "s"
      page.submit
    end

    expect_page ShowEncounterPage do |page|
      expect(page.encounter.test_results.count).to eq(1)
    end

    process sample: {id: "s"}

    visit current_path
    expect_page ShowEncounterPage do |page|
      expect(page.encounter.test_results.count).to eq(2)
    end
  end

  it "should be able to create fresh encounter with existing patient" do
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
end
