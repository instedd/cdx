Given(/^the user has an account$/) do
  institution = Institution.make
  @user1 = User.make(password: '12345678', first_name: 'Bob')
  @user1.grant_superadmin_policy
  authenticate(@user1)
  
  #needed for the @sites
  default_params =  {context: institution.uuid}
  @navigation_context = NavigationContext.new(@user1, default_params[:context])
end


Given(/^the user creates a new alert with name "(.*?)"$/) do |arg1|
  @alert = AlertPage.new
  @alert.load
      
  within(@alert.form) do |form|
    form.name.set arg1
    form.description.set 'aaaaa'
    form.errors.set '111'
    form.find('input[name="commit"]').click
  end
end


Then (/^the user should see in list alerts "(.*?)"$/) do |arg1|
  @alertIndex = AlertsIndexPage.new
  @alertIndex.load       
  expect(@alertIndex).to have_content(arg1)
end
          