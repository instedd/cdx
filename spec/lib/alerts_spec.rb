require 'spec_helper'
include Alerts


describe "AlertLib" do

  it "should test building build_mailing_list" do
    institution = Institution.make
    user = institution.user

    alert = Alert.make
    alert.user = user
    alert.name="test alert"
    alert.message="welcome"

    recipient1 = AlertRecipient.make
    recipient1.recipient_type = AlertRecipient.recipient_types["external_user"]
    recipient1.first_name="bob"
    recipient1.last_name="smith"
    recipient1.email="aa@aa.com"
    recipient1.telephone="123"
    recipient1.alert=alert
    recipient1.save

    recipient1a = AlertRecipient.make
    recipient1a.recipient_type = AlertRecipient.recipient_types["external_user"]
    recipient1.first_name="boba"
    recipient1a.last_name="smitha"
    recipient1a.email="aa@aaa.com"
    recipient1a.telephone="123a"
    recipient1a.alert=alert
    recipient1a.save

    recipient2 = AlertRecipient.make
    recipient2.recipient_type = AlertRecipient.recipient_types["internal_user"]
    recipient2.user = user
    recipient2.alert=alert
    recipient2.save

    theList = build_mailing_list(alert.alert_recipients)

    expect(theList.size).to eq(3)

  end
end
