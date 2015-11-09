require 'spec_helper'

describe "create encounter" do
  let(:device) { Device.make }
  let(:user) { device.institution.user }

  before(:each) {
    sign_in(user)
  }

  def process(args)
    DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(
      args.deep_merge({test:{assays:[condition: "flu_a", name: "flu_a", result: "positive"]}})
    )
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
      page.open_append_sample do |modal|
        modal.perform_search "ab"
        modal.results.first.select
      end

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
      page.open_add_tests do |modal|
        modal.perform_search "ab"
        modal.results.first.select
      end

      page.submit
    end

    expect_page ShowEncounterPage do |page|
      encounter = Encounter.find(page.id)
      expect(encounter.test_results).to match([TestResult.first])
    end
  end
end
