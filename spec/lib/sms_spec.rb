require 'spec_helper'
include Alerts


describe "SmsLib" do

  it "should test sending sms" do

    alert = Alert.make
    alert.name="test alert"
    alert.sms_message="welcome mr {lastname}"

    recipient = AlertRecipient.make
    recipient.recipient_type = AlertRecipient.recipient_types["external_user"]
    recipient.alert=alert

    tel_list=[]
    person = Hash.new
    person[:telephone] = "123444"
    person[:first_name] = recipient.first_name
    person[:last_name] = recipient.last_name
    person[:user_id] = nil
    person[:recipient_id] = recipient.id
    tel_list.push person


    recipient2 = AlertRecipient.make
    recipient2.recipient_type = AlertRecipient.recipient_types["external_user"]
    recipient2.telephone="456777"
    recipient2.alert=alert

    person2 = Hash.new
    person2[:telephone] = recipient2.telephone
    person2[:first_name] = recipient2.first_name
    person2[:last_name] = recipient2.last_name
    person2[:user_id] = nil
    person2[:recipient_id] = recipient2.id
    tel_list.push person2

    alert_history = AlertHistory.new
    alert_history.alert = alert

    binding.pry
    # send_ao
    =begin
    stub_request(:get, Settings.alert_sms_service_url).
    with(:query => hash_including(:family)).
    to_return(:status => 200, :body => "{'id'=>'2051719', 'guid'=>'69abea50-840e-50a0-77f9-547b38b2943e', 'token'=>'76beefab-9686-cd17-a3bc-d79dec6e0544'}", :headers => {})
    =end

    stub_request(:get, "https://CDx%2FCDx-Dev:cdx123cdx@nuntium.instedd.org/CDx/CDx-Dev/send_ao?body=welcome%20mr%20smith&from=sms://442393162302&to=sms://123444").
    with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
    to_return(:status => 200, :body => "{'id'=>'2051719', 'guid'=>'69abea50-840e-50a0-77f9-547b38b2943e', 'token'=>'76beefab-9686-cd17-a3bc-d79dec6e0544'}", :headers => {})


    aa=alert_sms_inform_recipient(alert, alert_history, tel_list, alert_count=0)

    binding.pry

    #mock api.send_ao sms_message


  end
end
