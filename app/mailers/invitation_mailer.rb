class InvitationMailer < ApplicationMailer
  def invite_message(user, role, message)
    @user = user
    @role = role
    @token = user.raw_invitation_token
    @message = message

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end

  def invite_institution_message(user, pending_institution_invite, message)
    @user = user
    @pending_institution_invite = pending_institution_invite
    @token = user.raw_invitation_token
    @message = message

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end

end
