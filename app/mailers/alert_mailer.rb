include Alerts

class AlertMailer < ApplicationMailer

  #TODO which  to use here?
  default from: 'notifications@cdx.com'

  def alert_email(alert, person, alert_history, alert_count)
    email=  person[:email]
    @alert = alert
    @alert_body_text = parse_alert_message(alert, person)
    subject_text = "CDX alert:"+alert.name

    if alert.aggregated?
      subject_text += " :occured times: "+alert_count.to_s
    end

    email_with_name = %("#{person[:first_name]}" <#{person[:email]}>)
    mail(to: email,subject: subject_text)

    #record it was send
    record_alert_message(alert, alert_history, person[:user_id], person[:recipient_id], subject_text)
  end

  private

  def parse_alert_message(alert,person)
    msg = alert.message
    msg.gsub! '{firstname}', person[:first_name]
    msg.gsub! '{lastname}', person[:last_name]
    msg.gsub! '{alertname}', alert.name
    msg.gsub! '{alertcategory}', alert.category_type
    return msg
  end

end
