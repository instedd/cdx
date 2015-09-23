Given(/^the user 'foouser' does not have an account$/) do
  @login = LoginPage.new
  @login.load
end

When(/^he attempts to log\-in$/) do
  @login.form.user_name.set 'foouser'
  @login.form.password.set 'foouser'
  @login.form.login.click
end

Then(/^he should see "(.*?)"$/) do |arg1|
  @login.should have_content(arg1)
end

When(/^he attempts to log\-in (\d+) times$/) do |cnt|
  cnt.to_i.times do
    @login.form.login.click
  end
end
