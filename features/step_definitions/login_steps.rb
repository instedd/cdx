def setup_user
  @user ||= User.make(
    password_changed_at: Time.now,
    password: 'abc123abc'
  )
end

Given(/^the user 'foouser@example\.com' has an account$/) do
  setup_user
end

When(/^he attempts to log\-in with incorrect password$/) do
  authenticate(@user, 'falsepassword')
end

When(/^he attempts to log\-in (\d+) times with incorrect password$/) do |cnt|
  cnt.to_i.times do
    authenticate(@user, 'falsepassword')
  end
end

When(/^he attempts to log\-in with correct details$/) do
  authenticate(@user)
end

Then(/^he should see "(.*?)"$/) do |arg1|
  @login.should have_content(arg1)
end
