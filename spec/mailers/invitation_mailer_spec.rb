require "spec_helper"

RSpec.describe InvitationMailer, type: :mailer do
  let!(:current_user) { User.new(email: "existing@example.com", first_name: "Current", last_name: "User") }
  let!(:invite) { PendingInstitutionInvite.make(invited_by_user: current_user) }
  let!(:new_user) {
    User.make(:invited_pending).tap do |user|
      user.__send__(:generate_invitation_token)
    end
  }
  let!(:existing_user) { User.make }

  it "#invite_message" do
    role = Role.make
    mail = InvitationMailer.invite_message(new_user, current_user, role, "custom message")

    expect(new_user.raw_invitation_token).not_to be_blank
    body = mail.body.to_s
    expect(body).to include(accept_user_invitation_url(current_user, :invitation_token => new_user.raw_invitation_token))
    expect(body).to include("custom message")
    expect(body).to include("Current User")
    expect(body).to include(role.name)
  end

  it "#create_institution_message" do
    mail = InvitationMailer.create_institution_message(existing_user, current_user, invite, "custom message")

    body = mail.body.to_s
    expect(body).to include(new_from_invite_data_institutions_url(:pending_institution_invite_id => invite.id))
    expect(body).to include("custom message")
    expect(body).to include(invite.institution_name)
    expect(body).to include("Current User")
  end

  it "#invite_institution_message" do
    mail = InvitationMailer.invite_institution_message(new_user, current_user, invite, "custom message")

    expect(new_user.raw_invitation_token).not_to be_blank
    body = mail.body.to_s
    expect(body).to include(ERB::Util.html_escape(accept_user_invitation_url(current_user, :invitation_token => new_user.raw_invitation_token, :pending_institution_invite_id => invite.id)))
    expect(body).to include("custom message")
    expect(body).to include(invite.institution_name)
    expect(body).to include("Current User")
  end
end
