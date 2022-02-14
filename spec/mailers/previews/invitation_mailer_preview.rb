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
    sender = User.new(email: "existing@example.com", first_name: "Current", last_name: "User")
    invitee = User.new(email: "new@example.com")
    invite = PendingInstitutionInvite.new(
      id: 12345,
      invited_by_user: sender,
      invited_user_email: invitee.email,
      institution_name: "New Institution",
      institution_kind: "institution",
    )
    InvitationMailer.create_institution_message(invitee, sender, invite, "custom message")
  end

  def invite_institution_message
    sender = User.new(email: "existing@example.com", first_name: "Current", last_name: "User")
    invitee = User.new(email: "new@example.com")
    invitee.__send__(:generate_invitation_token)
    invite = PendingInstitutionInvite.new(
      id: 12345,
      invited_by_user: sender,
      invited_user_email: invitee.email,
      institution_name: "New Institution",
      institution_kind: "institution",
    )

    InvitationMailer.invite_institution_message(invitee, sender, invite, "custom message")
  end
end
