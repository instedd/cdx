require 'spec_helper'

describe "invite user" do
  let(:institution) { Institution.make }
  let(:user) { institution.user }

  describe "from users list" do
    before(:each) {
      sign_in(user)
    }

    it "should allow invitee to login right after password setup" do
      goto_page UserViewPage do |page|
        page.open_invite_users do |modal|
          modal.role.set "#{institution.name} Admin"
          modal.users.set("sarah@acme.org")
          modal.users.native.send_keys :enter
          modal.submit
        end

        expect(page).to have_content 'Invitation sent'
        page.logout
      end

      expect(email_count).to eq(1)
      visit extract_invite_url(last_email)
      expect_page AcceptInvitiation do |page|
        page.password.set 'passw0rd'
        page.password_confirmation.set 'passw0rd'
        page.submit
      end

      expect(page).to have_content 'You are now signed in'
      expect(email_count).to eq(1)
    end

    it "should invite single user without pressing enter" do
      goto_page UserViewPage do |page|
        page.open_invite_users do |modal|
          modal.role.set "#{institution.name} Admin"
          modal.users.set("sarah@acme.org")
          modal.submit
        end

        expect(page).to have_content 'Invitation sent'
        expect(page).to have_content 'sarah@acme.org'
      end
    end
  end

  def extract_invite_url(email)
    email.parts[1].body.to_s[/\/users\/invitation[^"]*/]
  end

  def last_email
    ActionMailer::Base.deliveries.last
  end

  def email_count
    ActionMailer::Base.deliveries.count
  end

  describe "insitution invite" do
    context "new user" do
      let!(:new_user) {
        User.make(:invited_pending).tap do |user|
          user.send("generate_invitation_token!")
        end
      }
      let!(:invite) { PendingInstitutionInvite.make(invited_user_email: new_user.email, invited_by_user: user) }

      it "onboards invitee" do
        # TODO: Add invitation send workflow after it has been remodeled in #1430

        goto_page AcceptInvitiation, "query" => {invitation_token: new_user.raw_invitation_token, pending_institution_invite_id: invite.id} do |page|
          expect(page).to have_content "Set your password"
          expect(page.first_name.value).to eq new_user.first_name
          expect(page.last_name.value).to eq new_user.last_name

          page.password.set 'passw0rd'
          page.password_confirmation.set 'passw0rd'
          page.submit
        end

        expect_page InstitutionNewFromInvitePage do |page|
          expect(page).to have_content("New Institution")
          expect(page.name.value).to eq invite.institution_name
          # TODO: Checking the radio button doesn't work for some reason
          # expect(page).to have_checked_field("institution_kind_#{invite.institution_kind}")
          # page.choose("institution_kind_manufacturer")

          page.submit
        end

        # FIXME: This flash message probably shouldn't be there
        expect(page).to have_content("You are already signed in")
      end
    end
  end
end
