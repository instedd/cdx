require 'spec_helper'

describe "policy", elasticsearch: true do

  let(:institution) { Institution.make }
  let(:user) { institution.user }
  let!(:site1) { institution.sites.make }
  let!(:site2) { Site.make :child, parent: site1 }
  let!(:device_spec_helper) { DeviceSpecHelper.new 'genoscan' }

  before(:each) {
    sign_in(user)
  }

  context "Site Admin" do
    before(:each) {
      invite_accept_and_sign_in("Site #{site1.name} Admin", "sarah@acme.org", "passw0rd")
    }

    context "regarding target site" do
      let!(:device) { device_spec_helper.make site: site1 }

      before(:each) {
        device_spec_helper.import_sample_csv device, 'genoscan_sample.csv'
      }

      it "should access site details" do
        goto_page SiteEditPage, site_id: site1.id do |page|
          expect(page).to be_success
        end
      end

      it "should access first test result" do
        goto_page TestResultsPage do |page|
          page.table.items.first.click
          expect(page).to be_success
        end
      end
    end

    context "regarding target child site" do
      let!(:device) { device_spec_helper.make site: site2 }

      before(:each) {
        device_spec_helper.import_sample_csv device, 'genoscan_sample.csv'
      }

      it "should access site" do
        goto_page SiteEditPage, site_id: site2.id do |page|
          expect(page).to be_success
        end
      end

      it "should access first test result" do
        goto_page TestResultsPage do |page|
          page.table.items.first.click
          expect(page).to be_success
        end
      end
    end
  end

  def invite_accept_and_sign_in(role, email, password)
    # invite a new user to be the Site1 Admin
    goto_page UserViewPage do |page|
      page.open_invite_users do |modal|
        modal.role.set role
        modal.users.set email
        modal.users.native.send_keys :enter
        modal.submit
      end
      page.logout
    end

    # Accept the invitation
    visit extract_invite_url(last_email)
    expect_page AcceptInvitiation do |page|
      page.password.set password
      page.password_confirmation.set password
      page.submit
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
end
