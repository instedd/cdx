module Alerts

  include SMS

  def alert_history_check(frequency, alert_type)

    if alert_type == Alert.hour
      alerts = Alert.aggregated.hour.where({enabled: true})
    else
      alerts = Alert.aggregated.day.where({enabled: true})
    end

    # if it has just alert the user
    alerts.each do |alert|
      alertHistorycount=AlertHistory.where('alert_id=?', alert.id).where('created_at >= ?', frequency.ago).where('for_aggregation_calculation=true').count
      if (alertHistorycount > 0)
        alertHistory = AlertHistory.new
        alertHistory.alert = alert
        alertHistory.user = alert.user
        alertHistory.for_aggregation_calculation  = false
        alertHistory.save!

        recipients_list=build_mailing_list(alert.alert_recipients)
        alert_email_inform_recipient(alert, alertHistory, recipients_list, alertHistorycount)
      end
    end
  end


  def alert_email_inform_recipient(alert, alert_history, recipients_list, alert_count=0)

    #TODO look at Sending Email To Multiple Recipients, http://guides.rubyonrails.org/action_mailer_basics.html
    recipients_list.each do |person|
      message_body= parse_alert_message(alert, alert.message, person)

      subject_text = "CDX alert:"+alert.name
      if alert.aggregated?
        subject_text += " :occured times: "+alert_count.to_s
      end

      AlertMailer.alert_email(alert, person, alert_history, message_body, subject_text, alert_count).deliver_now
    end
  end


  def alert_sms_inform_recipient(alert, alert_history, recipients_list, alert_count=0)

    #TODO Can also send many messages at once. https://bitbucket.org/instedd/nuntium-api-ruby/wiki/Home
    recipients_list.each do |person|

      number_sms_sent_today = AlertHistory.calculate_number_sms_sent_today(alert.id)

      if (number_sms_sent_today <= alert.sms_limit)
        text_msg=parse_alert_message(alert, alert.sms_message, person)
        sms_response_fields=send_sms(person[:telephone], text_msg)

        record_alert_message(alert, alert_history, person[:user_id], person[:recipient_id], text_msg, sms_response_fields)
      else
        Rails.logger.info("sms limit exceeded for alert "+alert.id.to_s)
      end
    end
  end


  def record_alert_message(alert, alert_history, user_id, alert_recipient_id, messagebody, sms_response_fields=nil)
    recipientNotificationHistory = RecipientNotificationHistory.new
    recipientNotificationHistory.alert = alert
    recipientNotificationHistory.alert_history = alert_history
    recipientNotificationHistory.user_id = user_id if user_id != nil
    recipientNotificationHistory.alert_recipient_id = alert_recipient_id
    recipientNotificationHistory.message_sent = messagebody
    recipientNotificationHistory.channel_type = alert.channel_type

    if sms_response_fields != nil
      recipientNotificationHistory.sms_response_id = sms_response_fields[:id].to_i
      recipientNotificationHistory.sms_response_guid = sms_response_fields[:guid]
      recipientNotificationHistory.sms_response_token = sms_response_fields[:token]
    end

    recipientNotificationHistory.save
  end



  #build the email ist from roles, internal users,external users
  def build_mailing_list(recipients)
    email_list=[]
    recipients.each do |recipient|
      detail = Hash.new
      if recipient.recipient_type == "internal_user"
        detail[:email] = recipient.user.email
        detail[:telephone] = recipient.user.telephone
        detail[:first_name] = recipient.user.first_name
        detail[:last_name] = recipient.user.last_name
        detail[:user_id] = recipient.user.id
        detail[:recipient_id] = recipient.id
        email_list.push detail
      elsif recipient.recipient_type == "role"
        #find all users within roles
        recipient.role.users.each do |user|
          detail[:email] = user.email
          detail[:telephone] = user.telephone
          detail[:first_name] = user.first_name
          detail[:last_name] = user.last_name
          detail[:user_id] = user.id
          detail[:recipient_id] = recipient.id
          email_list.push detail
        end
      elsif recipient.recipient_type == "external_user"
        detail[:email] = recipient.email
        detail[:telephone] = recipient.telephone
        detail[:first_name] = recipient.first_name
        detail[:last_name] = recipient.last_name
        detail[:user_id] = nil
        detail[:recipient_id] = recipient.id
        email_list.push detail
      else
        p "no match"
      end
    end
    email_list
  end


  def parse_alert_message(alert, message, person)
    msg = message
    msg.gsub! '{firstname}', person[:first_name]
    msg.gsub! '{lastname}', person[:last_name]
    msg.gsub! '{alertname}', alert.name
    msg.gsub! '{alertcategory}', alert.category_type
    return msg
  end

end
