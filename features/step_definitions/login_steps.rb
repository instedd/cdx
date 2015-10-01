def login_user
  @login_user ||= User.make(password_changed_at: Time.now)
end

Given(/^the user 'foouser@example\.com' has an account$/) do
  @login = LoginPage.new
  @login.load
end

When(/^he attempts to log\-in with incorrect password$/) do
  @login.form.user_name.set login_user.email
  @login.form.password.set 'foouser'
  @login.form.login.click
end

When(/^he attempts to log\-in (\d+) times with incorrect password$/) do |cnt|
  cnt.to_i.times do
    @login.form.user_name.set login_user.email
    @login.form.password.set 'foouser'
    @login.form.login.click
  end
end

When(/^he attempts to log\-in with correct details$/) do
  @login.form.user_name.set login_user.email
  @login.form.password.set login_user.password
  @login.form.login.click
end

Then(/^he should see "(.*?)"$/) do |arg1|
  @login.should have_content(arg1)
end
