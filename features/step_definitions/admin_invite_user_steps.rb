Given(/^an authenticated superadmin called Bob$/) do
  @administrator = User.make(password: 'copado123', first_name: 'Bob')
  @administrator.grant_superadmin_policy
  @administrator.reload.update_computed_policies
  authenticate(@administrator)
end

Given(/^an institution name "(.*?)"$/) do |arg1|
  @institution = Institution.make(user_id: @administrator.id)
end

Given(/^a prospective user called Bill Smith, with email "(.*?)"$/) do |email|
  @user = User.make_unsaved(email: email)
end

Given(/^Bill does not have an account$/) do
  @invite_page = PolicyPage.new
  @invite_page.load
end

When(/^Bob sends an invitation to Bill Smith$/) do
  @invite_page = PolicyPage.new
  @invite_page.load
  @policy = canned_policy(@institution.id, {})
  within(@invite_page.form) do |f|
    f.email.set @user.email
    f.name.set @user.full_name
    f.policy.set @policy
    f.invite.click
  end
end

Given(/^the following users created by Bob$/) do |users|
  users.hashes.each do |user|
    site = Site.where(
      name: user[:lab_name], institution: @institution.id
    ).first_or_create

    user = User.make(
      first_name: user[:first_name],
      last_name: user[:last_name],
      roles: [site.roles.first]
    )
  end
end

When(/^Bob view the users on Lab One$/) do
  @site = Site.where(name: 'Lab One').first
  user_page = UserViewPage.new
  user_page.load(query: { context: @site.uuid })
end

Then(/^Bob should see "(.*?)"$/) do |message|
  page.should have_content(message)
end

Then(/^Bob should not see "(.*?)"$/) do |message|
  page.should_not have_content(message)
end
