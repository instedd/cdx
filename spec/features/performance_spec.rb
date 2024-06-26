require 'spec_helper'
require 'policy_spec_helper'

describe "performance", elasticsearch: true do
  let(:institution) { Institution.make! }
  let(:user) { institution.user }
  let(:site) { Site.make! institution: institution }
  let!(:device_spec_helper) { DeviceSpecHelper.new 'genexpert' }
  let!(:device) { device_spec_helper.make! site: site }

  before(:each) {
    device_spec_helper.import_sample_json device, 'genexpert_sample.json'
    device_spec_helper.import_sample_json device, 'genexpert_sample_qc.json'
    # FIXME: for some reason tests will start failing if we don't go through the
    #        login form to authenticate the user (?!)
    sign_in(user, login_form: true)
  }

  it "should have 2 test results" do
    expect(device.test_results.count).to eq(2)
  end

  it "dashboard charts should hide qc tests" do
    Timecop.travel(Time.utc(2015, 9, 1)) do
      goto_page DashboardPage do |page|
        expect(page.tests_run.pie_chart.total.text).to eq("1")
      end
    end
  end

  it "device charts should hide qc tests" do
    Timecop.travel(Time.utc(2015, 9, 1)) do
      goto_page DevicePage, id: device.id do |page|
        expect(page.tests_run.pie_chart.total.text).to eq("1")
      end
    end
  end
end
