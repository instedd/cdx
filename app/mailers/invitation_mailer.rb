class InvitationMailer < ApplicationMailer
  def invite_message(user, role, message)
    @user = user
    @role = role
    @token = user.raw_invitation_token
    @message = message

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end

  def invite_institution_message(user, pending_invite, message)
    @user = user
    @institution_name = pending_invite.institution_name
    @pending_institution_invite_id = pending_invite.id
    @token = user.raw_invitation_token
    @message = message

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end

  def create_institution_message(user, pending_invite, message)
    @user = user
    @institution_name = pending_invite.institution_name
    @pending_institution_invite_id = pending_invite.id
    @message = message

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end

end
