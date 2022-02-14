# Preview all emails at http://localhost:3000/rails/mailers/invitation_mailer
class InvitationMailerPreview < ActionMailer::Preview
  def invite_message
    current_user = User.new(email: "existing@example.com", first_name: "Current", last_name: "User")
    user = User.new(email: "new1@example.com", first_name: "Invited", last_name: "Person")
    user.invited_by = current_user
    user.__send__(:generate_invitation_token)
    InvitationMailer.invite_message(user, current_user, Role.new(name: "Senior Executive Parrot Specialist"), "custom message")
  end

  def create_institution_message
    invite = PendingInstitutionInvite.new
    invite.id = 12345
    current_user = User.new(email: "existing@example.com", first_name: "Current", last_name: "User")
    invite.invited_by_user = current_user
    invite.invited_user_email = "new@example.com"
    invite.institution_name = "New Institution"
    invite.institution_kind = "institution"
    new_user = User.new(email: "new@example.com")
    InvitationMailer.create_institution_message(new_user, current_user, invite, "custom message")
  end

  def invite_institution_message
    invite = PendingInstitutionInvite.new
    invite.id = 12345
    current_user = User.new(email: "existing@example.com", first_name: "Current", last_name: "User")
    invite.invited_by_user = current_user
    invite.invited_user_email = "new@example.com"
    invite.institution_name = "New Institution"
    invite.institution_kind = "institution"
    new_user = User.new(email: "new@example.com")
    new_user.__send__(:generate_invitation_token)
    InvitationMailer.invite_institution_message(new_user, current_user, invite, "custom message")
  end
end
