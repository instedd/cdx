def user
  @user ||= User.make ({:isAdmin => true})
end


#scenario background
#seeds.rb would be faste but concerned about people calling it for production data not just test
When (/^I create test users$/) do
  User.make ({:email => 'aa1@test.com', :password => "11111111",  :active => "true", :archived => true})
  User.make ({:email => 'aa2@test.com', :password => "11111111",  :active => "true", :archived => false})
  User.make ({:email => 'aa3@test.com', :password => "11111111",  :active => "false", :archived => false})
  User.make ({:email => 'aa4@test.com', :password => "11111111",  :active => "true", :archived => false})
  User.make ({:email => 'aa5@test.com', :password => "11111111",  :active => "false", :archived => true})
end


Given (/^I log in as an admin$/) do
  @user =User.make
  @user.grant_superadmin_policy
    
  @login = LoginPage.new
  @login.load
  @login.form.user_name.set user.email
  @login.form.password.set user.password
  @login.form.login.click
        
  visit '/admin/users'
end


Then (/^I should be taken to the dashboard$/) do
  page.should have_content("Dashboard")
end


When (/^I click the user tab$/) do
  page.should have_content("Users")
end


When (/^I select the ENABLED button "(.*?)"$/) do | buttonOption|
  select( buttonOption, :from => 'Enabled')
  click_button 'Filter'
end

When (/^I select the ARCHIVED button "(.*?)"$/) do | buttonOption|
  select( buttonOption, :from => 'Archived')
  click_button 'Filter'
end


Then (/^I should see a list of (\d+) users$/) do | amount|
  page.should have_content("Displaying all "+amount.to_s+" Users");
end



