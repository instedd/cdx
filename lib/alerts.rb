module Alerts

  ##
  # Note: it is assumed that rake db:seed has been called to load the seeds data generated.
  #
  # if say 1000 daily testresults are needed per device, then loop over the device templates (only two at the moment)
  

     #parse the message
  def parse_alert_message(alert)
    alert_message.gsub!(/\w+{alertname}/, alert.name)
    alert_message.gsub!(/\w+{alertcategory}/, alert.category)
  end
    
  
  def alert_history_check(frequency, alert_type)

    alerts = Alert.aggregated.hour.where({enabled: true})

    #for each alert check if it has occured in alert history in the last hour
    # if it has just alert the user

    alerts.each do |alert|
#    if ( (alertHistorycount=AlertHistory.where('alert_id=?', alert.id).where('created_at >= ?', frequency.ago).count ) > 0 )  
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
     AlertMailer.alert_email(alert, alert_history, alert_count).deliver_now   
   end 
  
  def record_alert_message(alert, alert_history, user, messagebody)
    recipientNotificationHistory = RecipientNotificationHistory.new
    recipientNotificationHistory.alert = alert
    recipientNotificationHistory.alert_history = alert_history
    recipientNotificationHistory.user = user
#    recipientNotificationHistory.alert_recipient = alert_recipient
    recipientNotificationHistory.message_sent = messagebody
    recipientNotificationHistory.channel_type = alert.channel_type
    recipientNotificationHistory.save
  end
    
    
end