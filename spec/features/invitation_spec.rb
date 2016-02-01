require 'spec_helper'

describe "invite user" do
  let(:institution) { Institution.make }
  let(:user) { institution.user }
  before(:each) {
    sign_in(user)
  }

  describe "from users list" do
    it "should allow invitee to login right after password setup" do
      goto_page UserViewPage do |page|
        page.open_invite_users do |modal|
          modal.role.set "#{institution.name} Admin"
          modal.users.set "sarah@acme.org"
          modal.submit
        end

        expect(page).to have_content 'Invitation sent'
        page.logout
      end

      visit extract_invite_url(last_email)
      expect_page AcceptInvitiation do |page|
        page.password.set 'passw0rd'
        page.password_confirmation.set 'passw0rd'
        page.submit
      end

      expect(page).to have_content 'You are now signed in'
    end
  end

  def extract_invite_url(email)
    email.parts[1].body.to_s[/\/users\/invitation[^"]*/]
  end

  def last_email
    ActionMailer::Base.deliveries.last
  end
end
