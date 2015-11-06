require 'spec_helper'

describe "create encounter" do
  let(:device) { Device.make }
  let(:user) { device.institution.user }

  before(:each) {
    sign_in(user)
  }

  def process_sample(id)
    DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(
      test:{assays:[condition: "flu_a", name: "flu_a", result: "positive"]}, sample: {id: id}
    )
  end

  it "should search sample by id substring" do
    process_sample "ab111"
    process_sample "22ab2"
    process_sample "xy333"

    goto_page NewEncounterPage do |page|
      page.open_append_sample do |modal|
        modal.perform_search "ab"
        expect(modal.results.count).to eq(2)
      end
    end
  end

  it "should add sample to encounter on save" do
    process_sample "ab111"

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

end
