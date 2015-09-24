def user
  @user ||= User.make
end

Given(/^the user 'foouser@example\.com' has an account$/) do
  @login = LoginPage.new
  @login.load
end

When(/^he attempts to log\-in with incorrect password$/) do
  @login.form.user_name.set user.email
  @login.form.password.set 'foouser'
  @login.form.login.click
end

When(/^he attempts to log\-in (\d+) times with incorrect password$/) do |cnt|
  cnt.to_i.times do
    @login.form.user_name.set user.email
    @login.form.password.set 'foouser'
    @login.form.login.click
  end
end

When(/^he attempts to log\-in with correct details$/) do
  @login.form.user_name.set user.email
  @login.form.password.set user.password
  @login.form.login.click
end

Then(/^he should see "(.*?)"$/) do |arg1|
  @login.should have_content(arg1)
end
