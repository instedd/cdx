require "spec_helper"

RSpec.describe AlertMailer, type: :mailer do

  before(:each) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    alert = Alert.make
    alert.name="test alert"
    alert.message="welcome mr {lastname}"

    recipient = AlertRecipient.make
    recipient.recipient_type = AlertRecipient.recipient_types["external_user"]
    recipient.alert=alert

    person = Hash.new
    person[:email] = recipient.email
    person[:first_name] = recipient.first_name
    person[:last_name] = recipient.last_name
    person[:user_id] = nil
    person[:recipient_id] = recipient.id
 
    alert_history = AlertHistory.new
    alert_history.alert = alert

    alert_count=0
    message_body= parse_alert_message(alert, alert.message, person)
    subject_text = "CDX alert:"+alert.name
    
    AlertMailer.alert_email(alert, person, alert_history, message_body, subject_text, alert_count).deliver_now
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  it 'should send an email' do
    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end

  it 'renders the receiver email' do
    expect(ActionMailer::Base.deliveries.first.to).to eq(["aaa@aaa.com"])
  end

  it 'should set the subject to the correct subject' do
    expect(ActionMailer::Base.deliveries.first.subject).to  eq('CDX alert:test alert')
  end

  it 'should set the body to the correct alert' do
    expect(ActionMailer::Base.deliveries.first.body.encoded).to  include('Alert occurred test alert')
  end

  it 'should set the body to parsed firstname {firstname}' do
    expect(ActionMailer::Base.deliveries.first.body.encoded).to  include('welcome mr smith')
  end
  
  it 'renders the sender email' do
    expect(ActionMailer::Base.deliveries.first.from).to eq(['notifications@cdx.com'])
  end

end
