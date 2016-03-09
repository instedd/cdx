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
      begin
        alert_history_count=AlertHistory.where('alert_id=?', alert.id).where('created_at >= ?', frequency.ago).where('for_aggregation_calculation=true').count
        if alert_history_count > 0
          if !alert.use_aggregation_percentage?
            if alert.aggregation_threshold > alert_history_count
              alert_history_triggered(alert, alert_history_count)
            end
          else
            total_results = find_number_test_results_since(alert, frequency)
            if total_results > 0
              percentage = (alert_history_count.to_f / total_results.to_f) * 100

              if percentage >= alert.aggregation_threshold
                #store percentage
                alert_history_triggered(alert, alert_history_count, percentage.round(2))
              end
            end
          end
        end
      rescue => e
        Rails.logger.error {"Encountered an error when trying to run alert_history_check : #{alert.id}, #{e.message} #{e.backtrace.join("\n")}" }
      end
    end
  end


  def find_number_test_results_since(alert, frequency)
    total_results_query = TestResult.where("created_at > ?",frequency).where("institution_id=?", alert.institution_id)
    if alert.sites.size > 0
      site_id_list = alert.sites.map { |site| site.id }
      total_results_query = total_results_query.where("site_id in (?)", site_id_list)
    end

    if alert.devices.size > 0
      device_id_list = alert.devices.map { |device| device.id }
      total_results_query = total_results_query.where("device_id in (?)", device_id_list)
    end
    total_results_query.count
  end


  def alert_history_triggered(alert, alert_history_count, percentage=0)
    alertHistory = AlertHistory.new
    alertHistory.alert = alert
    alertHistory.user = alert.user
    alertHistory.for_aggregation_calculation = false
    alertHistory.save!

    recipients_list=build_mailing_list(alert.alert_recipients)
    if (alert.email? || alert.email_and_sms?)
      alert_email_inform_recipient(alert, alertHistory, recipients_list, alert_history_count, percentage)
    end

    if (alert.sms? || alert.email_and_sms?)
      alert_sms_inform_recipient(alert, alertHistory, recipients_list, alert_history_count, percentage)
    end
  end


  def alert_email_inform_recipient(alert, alert_history, recipients_list, alert_count=0, percentage=0)
    #TODO look at Sending Email To Multiple Recipients, http://guides.rubyonrails.org/action_mailer_basics.html
    recipients_list.each do |person|
      number_alert_messages_sent_today = AlertHistory.calculate_number_alert_messages_sent_today(alert.id)

      if (number_alert_messages_sent_today <= alert.email_limit)
        message_body= parse_alert_message(alert, alert.message, person, alert_count, percentage)
        subject_text = "CDX alert:"+alert.name
        if alert.aggregated?
          subject_text += " occured "+alert_count.to_s + " times."

          if alert.use_aggregation_percentage?
            subject_text += " Percentage "+percentage.to_s
          end
        end
        AlertMailer.alert_email(alert, person, alert_history, message_body, subject_text, alert_count).deliver_now
      else
        Rails.logger.info("email limit exceeded for alert "+alert.id.to_s)
      end
    end
  end
  

  def alert_sms_inform_recipient(alert, alert_history, recipients_list, alert_count=0, percentage=0)
    #TODO Can also send many messages at once. https://bitbucket.org/instedd/nuntium-api-ruby/wiki/Home
    recipients_list.each do |person|
      number_alert_messages_sent_today = AlertHistory.calculate_number_alert_messages_sent_today(alert.id)

      if (number_alert_messages_sent_today <= alert.sms_limit)
        text_msg=parse_alert_message(alert, alert.sms_message, person, alert_count, percentage)
        sms_response_fields=send_sms(person[:telephone], text_msg)
        record_alert_message(alert, alert_history, person[:user_id], person[:recipient_id], text_msg, Alert.channel_types["sms"], sms_response_fields)
      else
        Rails.logger.info("sms limit exceeded for alert "+alert.id.to_s)
      end
    end
  end

  def record_alert_message(alert, alert_history, user_id, alert_recipient_id, messagebody, channel_type, sms_response_fields=nil)
    recipientNotificationHistory = RecipientNotificationHistory.new
    recipientNotificationHistory.alert = alert
    recipientNotificationHistory.alert_history = alert_history
    recipientNotificationHistory.user_id = alert.user.id
    recipientNotificationHistory.alert_recipient_id = alert_recipient_id
    recipientNotificationHistory.message_sent = messagebody
    recipientNotificationHistory.channel_type = channel_type

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

  def parse_alert_message(alert, message, person, alert_count=0, percentage=0)
    msg = message
    msg.gsub! '{firstname}', person[:first_name]
    msg.gsub! '{lastname}', person[:last_name]
    msg.gsub! '{alertname}', alert.name
    msg.gsub! '{alertcategory}', alert.category_type
    msg.gsub! '{alertcount}', alert_count.to_s
    msg.gsub! '{alertpercentage}', percentage.to_s
    return msg
  end
end
