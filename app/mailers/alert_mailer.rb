class AlertMailer < ApplicationMailer

  default from: 'notifications@cdx.com'

  def alert_email(alert, alert_history, alert_count)
    #TODO email_with_name = %("#{@user.name}" <#{@user.email}>)

    #just do the first recipient now

    #get all the recipient email
    recipients = alert.alert_recipients
    recipients.each do |recipient|
      role=Role.find_by_id(recipient.role_id)
      users = role.users

      users.each do |user|
        #      email=  alert.alert_recipients[0].user.email
        email=  user.email
        @alert = alert

        subject_text = alert.name

        #  parse_alert_message(alert)

        if alert.aggregated?
          subject_text += " :occured times: "+alert_count.to_s
        end

        mail(to: email, subject: subject_text)

        #record it was send
        record_alert_message(alert, alert_history, user, subject_text)

        #http://guides.rubyonrails.org/action_mailer_basics.html
        #TODO check html, and palin text formats
        #format.html { render 'another_template' }
        #format.text { render text: 'Render text' }
      end
    end

  end  
end
