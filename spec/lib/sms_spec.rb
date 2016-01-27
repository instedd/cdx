require 'spec_helper'
include Alerts


describe "SmsLib" do

  before(:each) do
      stub_request(:get, "https://CDx%2FCDx-Dev:cdx123cdx@nuntium.instedd.org/CDx/CDx-Dev/send_ao?body=welcome%20mr%20smith&from=sms://442393162302&to=sms://123444").
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "{'id'=>'2051719', 'guid'=>'69abea50-840e-50a0-77f9-547b38b2943e', 'token'=>'76beefab-9686-cd17-a3bc-d79dec6e0544'}", :headers => {})

      stub_request(:get, "https://CDx%2FCDx-Dev:cdx123cdx@nuntium.instedd.org/CDx/CDx-Dev/send_ao?body=welcome%20mr%20smith&from=sms://442393162302&to=sms://456777").
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "{'id'=>'2051719', 'guid'=>'69abea50-840e-50a0-77f9-547b38b2943e', 'token'=>'76beefab-9686-cd17-a3bc-d79dec6e0544'}", :headers => {})
  end
  
context "sms operation" do
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


    alert_sms_inform_recipient(alert, alert_history, tel_list, alert_count=0)

    expect(RecipientNotificationHistory.count).to eq(2)
  end
 
end

=begin
context "sms exceeded" do 
  
   it "should test exceeding sms limit" do
    
     
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
     
     alert_history = AlertHistory.new
     alert_history.alert = alert
     
     alert.sms_limit=2
     
     alert.error_code=155
     binding.pry
     alert.category_type= "device_errors"
     alert.save
 
 
#insert test result
binding.pry
     user = User.make 
      institution = Institution.make user_id: user.id 
      site =  Site.make institution: institution 
      device =  Device.make institution: institution, site: site 
      data = Oj.dump test:{assays: [result: :positive]} 
      

#  DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(test:{assays:[condition: "flu_a"]}, sample: {id: 'a'}, patient: {id: 'a'})

     DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :negative], error_code: 155}, sample: {id: 'a'}, patient: {id: 'a',gender: :male})
    
    
    
     
  
#     alert_sms_inform_recipient(alert, alert_history, tel_list, alert_count=0)
#     binding.pry
#     alert_sms_inform_recipient(alert, alert_history, tel_list, alert_count=0)
#     binding.pry
#     alert_sms_inform_recipient(alert, alert_history, tel_list, alert_count=0)
#     binding.pry
#    alert_sms_inform_recipient(alert, alert_history, tel_list, alert_count=0)
    
     binding.pry
     expect(RecipientNotificationHistory.count).to eq(2)
     
   end
end
=end

  
end
