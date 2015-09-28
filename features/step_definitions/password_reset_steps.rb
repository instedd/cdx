def user
  @user ||= User.make(password_changed_at: 3.months.ago)
end

Given(/^User foo@example\.com has not changed password for (\d+) months$/) do |arg1|
  @login = LoginPage.new
  @login.load
end

When(/^they log\-in to app$/) do
  @login.form.user_name.set user.email
  @login.form.password.set user.password
  @login.form.login.click
end

Then(/^they should see, "(.*?)"$/) do |arg1|
  @login.should have_content(arg1)
end
