module Alerts


  def alert_history_check(frequency, alert_type)
    alerts = Alert.aggregated.hour.where({enabled: true})

    #for each alert check if it has occured in alert history in the last hour
    # if it has just alert the user
    alerts.each do |alert|
      if ( (alertHistorycount=AlertHistory.where('alert_id=?', alert.id).where('created_at >= ?', frequency.ago).where('for_aggregation_calculation=true').count ) > 0 )
        alertHistory = AlertHistory.new
        alertHistory.alert = alert
        alertHistory.user = alert.user
        alertHistory.for_aggregation_calculation  = false
        alertHistory.save!

        alert_inform_recipient(alert, alertHistory, alertHistorycount)
      end
    end
  end

  def alert_inform_recipient(alert, alert_history, alert_count=0)
    email_list=build_mailing_list(alert.alert_recipients)

    #TODO look at Sending Email To Multiple Recipients, http://guides.rubyonrails.org/action_mailer_basics.html
    email_list.each do |person|
      AlertMailer.alert_email(alert, person, alert_history, alert_count).deliver_now
    end

  end

  def record_alert_message(alert, alert_history, user_id, alert_recipient_id, messagebody)
    recipientNotificationHistory = RecipientNotificationHistory.new
    recipientNotificationHistory.alert = alert
    recipientNotificationHistory.alert_history = alert_history
    recipientNotificationHistory.user_id = user_id if user_id != nil
    recipientNotificationHistory.alert_recipient_id = alert_recipient_id
    recipientNotificationHistory.message_sent = messagebody
    recipientNotificationHistory.channel_type = alert.channel_type
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


end
