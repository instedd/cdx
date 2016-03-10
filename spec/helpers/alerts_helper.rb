require 'spec_helper'
require 'policy_spec_helper'

RSpec.describe AlertsHelper, type: :helper do
  describe "display_sites" do


    it "should display sites" do
      alert = Alert.make
      institution1 = Institution.make
      institution2 = Institution.make
      site1 = Site.make institution: institution1
      site2 = Site.make institution: institution2
      alert.sites << site1
      alert.sites << site2

      expect(display_sites(alert)).to eq("Mr. Alphonso Witting,Ross Senger")
    end

    it "display_latest_alert_date" do
      alert = Alert.make
      alertHistory = AlertHistory.new
      alertHistory.alert = alert
      alertHistory.save

      #format expected: "January 15, 2016 16:32" , a very basic test
      StrFormat = display_latest_alert_date(alert)
      expect(StrFormat.count(' ')).to eq(3)
      expect(StrFormat.count(':')).to eq(1)
      expect(StrFormat.count(',')).to eq(1)
    end

  end
end
