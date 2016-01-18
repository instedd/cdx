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


=begin
    it "should display roles" do
      alert = Alert.make

      granter_1= User.make
      institution_1=granter_1.create Institution.make
      granter_2 = User.make
      institution_2= granter_2.create Institution.make
      user_institution_1= User.make
      user_site_1=User.make
      user_institution_2= User.make
      site_1=Site.make(institution_id: institution_1.id)

      policy_1 = Policy.make(definition: policy_definition(institution_1, READ_INSTITUTION, false), granter_id: granter_1.id, user_id: user_institution_1)
      policy_2 = Policy.make(definition: policy_definition(institution_2, READ_INSTITUTION, false), granter_id: granter_2.id, user_id: user_institution_2)
      policy_3 = Policy.make(definition: policy_definition(site_1, READ_SITE, false), granter_id: granter_1.id, user_id: user_site_1)


      alertRecipient1 = AlertRecipient.new
      alertRecipient1.role = Role.make(institution: institution_1, policy: policy_1)
      alertRecipient1.alert=alert

      alertRecipient2 = AlertRecipient.new
      alertRecipient2.role = Role.make(institution: institution_1, site: site_1, policy: policy_3)
      alertRecipient2.alert=alert

      expect(display_roles(alert)).to eq("Mr. Alphonso Witting,Ross Senger")
    end
=end

    it "display_latest_alert_date" do
      alert = Alert.make
      alertHistory = AlertHistory.new
      alertHistory.alert = alert
      alertHistory.save

      #format expected: "January 15, 2016 16:32"
      #very basic test
      StrFormat = display_latest_alert_date(alert)
      expect(StrFormat.count(' ')).to eq(3)
      expect(StrFormat.count(':')).to eq(1)
      expect(StrFormat.count(',')).to eq(1)
    end


  end
end


