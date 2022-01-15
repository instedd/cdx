class InvitationMailer < ApplicationMailer
  def invite_message(user, role, message)
    @user = user
    @role = role
    @token = user.raw_invitation_token
    @message = message

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end

  def invite_institution_message(user, institution_name, message)
    @user = user
    @institution_name = institution_name
    @token = user.raw_invitation_token
    @message = message

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end

  def create_institution_message(user, institution_name, message)
    @user = user
    @institution_name = institution_name
    @message = message

    mail(:to => @user.email, :subject => "Invitation to Connected Diagnostics")
  end

end
