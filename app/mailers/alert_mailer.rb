class AlertMailer < ApplicationMailer
  
  default from: 'notifications@cdx.com'
  
  def alert_email(alert)
    #TODO email_with_name = %("#{@user.name}" <#{@user.email}>)
   
    #just do the first recipient now
    email=  alert.alert_recipients[0].user.email
    @alert = alert
    mail(to: email, subject: alert.name)
    
    #http://guides.rubyonrails.org/action_mailer_basics.html
    #TODO check html, and palin text formats
    #format.html { render 'another_template' }
    #format.text { render text: 'Render text' }    
  end

end



