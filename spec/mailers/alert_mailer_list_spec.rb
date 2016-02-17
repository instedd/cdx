require "spec_helper"

RSpec.describe AlertMailer, type: :mailer do


  after(:each) do
     ActionMailer::Base.deliveries.clear
   end
   

  it 'should send an email' do

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    alert = Alert.make
    alert.name="test alert"
    alert.message="welcome mr {lastname}"

    recipient = AlertRecipient.make
    recipient.recipient_type = AlertRecipient.recipient_types["external_user"]
    recipient.alert=alert

    email_list=[]
    person = Hash.new
    person[:email] = recipient.email
    person[:first_name] = recipient.first_name
    person[:last_name] = recipient.last_name
    person[:user_id] = nil
    person[:recipient_id] = recipient.id
    email_list.push person


    recipient2 = AlertRecipient.make
    recipient2.recipient_type = AlertRecipient.recipient_types["external_user"]
    recipient2.email="ddd@ggg.com"
    recipient2.alert=alert

    person2 = Hash.new
    person2[:email] = recipient2.email
    person2[:first_name] = recipient2.first_name
    person2[:last_name] = recipient2.last_name
    person2[:user_id] = nil
    person2[:recipient_id] = recipient2.id
    email_list.push person2

    alert_history = AlertHistory.new
    alert_history.alert = alert
    alert_email_inform_recipient(alert, alert_history, email_list)

    expect(ActionMailer::Base.deliveries.count).to eq(2)
  end



end
