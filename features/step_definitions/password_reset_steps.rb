def user
  @user ||= User.make
end

def login
  login_page = LoginPage.new
  login_page.load
  form = login_page.form
  form.user_name.set user.email
  form.password.set user.password
  form.login.click
end

Given(/^User foo@example\.com has not changed password for (\d+) months$/) do |arg1|
  user.password_changed_at = 3.months.ago
  user.save!
end

When(/^they log\-in to app$/) do
  login
end

Given(/^the previous passwords$/) do |table|
  @prev_passwords = table.raw.flatten[1..-1].unshift(user.password)
  table.hashes.each do |hash|
    user.password = hash['password']
    user.password_confirmation = hash['password']
    user.save!
  end
  user.password_changed_at = 3.months.ago
  user.save!
end

When(/^they try to use one of previous (\d+) passwords$/) do |arg1|
  login
  password_change = PasswordChange.new
  password_change.load
  form = password_change.form
  form.current_password.set @prev_passwords.last
  form.new_password.set @prev_passwords[2]
  form.confirm_password.set @prev_passwords[2]
  form.submit.click
end

Then(/^they should see, "(.*?)"$/) do |arg1|
  page.should have_content(arg1)
end
