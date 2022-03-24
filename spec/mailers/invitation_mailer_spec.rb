require "spec_helper"

RSpec.describe InvitationMailer, type: :mailer do
  let!(:current_user) { User.new(email: "existing@example.com", first_name: "Current", last_name: "User") }
  let!(:invite) { PendingInstitutionInvite.make(invited_by_user: current_user) }
  let!(:new_user) { User.make(:invited_pending) }
  let!(:existing_user) { User.make }

  def assert_link(html, url)
    expect(html.search("a[href]").map { |a| a["href"] }).to include(url)
  end

  it "#invite_message" do
    role = Role.make
    mail = InvitationMailer.invite_message(new_user, current_user, role, "custom message")

    expect(new_user.raw_invitation_token).not_to be_blank
    html = Nokogiri::HTML(mail.body.to_s)
    assert_link(html, accept_user_invitation_url(current_user, :invitation_token => new_user.raw_invitation_token))
    body = html.content
    expect(body).to include("custom message")
    expect(body).to include("Current User")
    expect(body).to include(role.name)
  end

  it "#create_institution_message" do
    mail = InvitationMailer.create_institution_message(existing_user, current_user, invite, "custom message")

    html = Nokogiri::HTML(mail.body.to_s)
    assert_link(html, new_institution_url(:pending_institution_invite_id => invite.id))
    body = html.content
    expect(body).to include("custom message")
    expect(body).to include(invite.institution_name)
    expect(body).to include("Current User")
  end

  it "#invite_institution_message" do
    mail = InvitationMailer.invite_institution_message(new_user, current_user, invite, "custom message")

    expect(new_user.raw_invitation_token).not_to be_blank
    html = Nokogiri::HTML(mail.body.to_s)
    assert_link(html, accept_user_invitation_url(current_user, :invitation_token => new_user.raw_invitation_token, :pending_institution_invite_id => invite.id))
    body = html.content
    expect(body).to include("custom message")
    expect(body).to include(invite.institution_name)
    expect(body).to include("Current User")
  end
end
