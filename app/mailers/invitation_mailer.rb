class InvitationMailer < ApplicationMailer
  def invite_message(user, message)
    @user = user
    @token = user.raw_invitation_token
    @message = message
    invitation_link = accept_user_invitation_url(:invitation_token => @token)

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end
end
