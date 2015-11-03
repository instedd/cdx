Given(/^an authenticated superadmin called Bob$/) do
  @administrator = User.make(password: 'copado123', first_name: 'Bob')
  @administrator.grant_superadmin_policy
  authenticate(@administrator)
end

Given(/^an institution name "(.*?)"$/) do |arg1|
  @institution = Institution.make(user_id: @administrator.id)
end

Given(/^a prospective user called Bill Smith, with email "(.*?)"$/) do |email|
  @user = User.make_unsaved(email: email)
end

Given(/^Bill does not have an account$/) do
  @invite_page = InvitePage.new
  @invite_page.load
end

When(/^Bob sends an invitation to Bill Smith$/) do
  @policy = canned_policy(@institution.id)
  within(@invite_page.form) do |f|
    f.email.set @user.email
    f.policy.set canned_policy
    f.invite.click
  end
end

Then(/^Bob should see "(.*?)"$/) do |message|
  @invite_page.should have_content(message)
end
