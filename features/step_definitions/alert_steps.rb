def setup_user
  @user ||= User.make(
    password_changed_at: Time.now,
    password: 'abc123abc',
    email: 'dd@aa6.com'
  )
end



#Given(/^the user 'foouser@example\.com' has an account$/) do
Given(/^the user has an account$/) do
 # binding.pry
  setup_user
  authenticate(@user)
end


Then(/^he should see New Institution$/)  do
  @login.should have_content('New Institution')
end


    Given(/^the user creates a new alert$/) do
#      binding.pry
      @alert = AlertPage.new
      @alert.load
      
      screenshot_and_save_page
      
      within(@alert.form) do |form|
 #         binding.pry
 #         form.title.set 'alert123'
 #         form.errors.set '111'
        form.login.click
      end
      

    end

    When(/^the user selects errorcode alert called "(.*?)"$/) do |arg1|
  #    @login.should have_content(arg1)
    end

    And (/^the user presses submit$/) do
  #      authenticate(@user)
      end
      
      
    Then (/^the should see in list alerts "(.*?)"$/) do |arg1|
      #    @login.should have_content(arg1)
        end      