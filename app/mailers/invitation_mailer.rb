class InvitationMailer < ApplicationMailer
  def invite_message(user, invitation_sender, role, message)
    @user = user
    @invitation_sender = invitation_sender
    @role = role
    @token = user.raw_invitation_token
    @message = message

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end

  def invite_institution_message(user, invitation_sender, pending_invite, message)
    @user = user
    @invitation_sender = invitation_sender
    @institution_name = pending_invite.institution_name
    @pending_institution_invite_id = pending_invite.id
    @token = user.raw_invitation_token
    @message = message

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end

  def create_institution_message(user, invitation_sender, pending_invite, message)
    @user = user
    @invitation_sender = invitation_sender
    @institution_name = pending_invite.institution_name
    @pending_institution_invite_id = pending_invite.id
    @message = message

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end

end
