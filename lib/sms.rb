module SMS

  require 'nuntium'

  # To send an sms go direct to numtium, no need to go via hub/mbuilder.
  #   https://rubygems.org/gems/nuntium_api/versions/0.21
  #   https://bitbucket.org/instedd/nuntium-api-ruby/wiki/Home
  #   http://nuntium.instedd.org/channels
  def send_sms(telephone, text_msg)

    #api = Nuntium.new "service_url", "account_name", "application_name", "application_password"
    api = Nuntium.new Settings.alert_sms_service_url, Settings.alert_sms_account_name, Settings.alert_sms_application_name, Settings.alert_sms_application_password
    
    from_tel = Settings.alert_sms_from_tel
    to_tel = "sms://"+telephone

    sms_message = {
      :from => from_tel,
      :to => to_tel,
      :body => text_msg
    }

    response = api.send_ao sms_message
  end

end
