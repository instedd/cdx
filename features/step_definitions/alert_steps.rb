Given(/^the user has an account$/) do
  institution = Institution.make
  @user = User.make(password: '12345678', first_name: 'Bob', email: 'zaa1aa@ggg.com')
  @user.grant_superadmin_policy
  authenticate(@user)

  #needed for the @sites
  default_params =  {context: institution.uuid}
  @navigation_context = NavigationContext.new(@user, default_params[:context])
end


Given(/^the user creates a new alert with name "(.*?)"$/) do |arg1|
  @alert = AlertPage.new
  @alert.load

  within(@alert.form) do |form|
    form.name.set arg1
    form.description.set 'aaaaa'
    form.message.set 'bbb'
    form.submit.click
  end
end



Given(/^the user creates a new error category alert with all fields with name "(.*?)"$/) do |arg1|

=begin
  institution2 = Institution.make user: @user
  site2 = institution2.sites.make
  device2 = site2.devices.make
=end 

  @alert = AlertPage.new
  @alert.load

  within(@alert.form) do |form|
    form.name.set arg1
    form.description.set 'aaaaa'
    form.message.set 'web msg'
    form.smsmessage.set 'sms msg'
    form.smslimit.set 2

    form.choose 'device_errors'
    form.device_errors_value.set 2

    form.aggregation.set "aggregated"
    form.aggregation_frequency.set "day"

    form.channel.set_exact "sms"

    form.submit.click
  end
end


Given(/^the user creates a new anomalie category alert with all fields with name "(.*?)"$/) do |arg1|

   institution2 = Institution.make user: @user
 #  site2 = institution2.sites.make
 #   site2= Site.make institution: (Institution.make user: @user)
   #device2 = site2.devices.make


  @alert = AlertPage.new
  @alert.load

  within(@alert.form) do |form|
    form.name.set arg1
    form.description.set 'aaaaa'
    form.message.set 'web msg'
    form.smsmessage.set 'sms msg'
    form.smslimit.set 2

    form.choose 'anomalies'
    form.anomalies.set "missing_start_time"

    form.aggregation.set "aggregated"
    form.aggregation_frequency.set "day"

    form.channel.set_exact "sms"

    form.submit.click
  end
end


Then (/^the user should see in list alerts "(.*?)"$/) do |arg1|
  @alertIndex = AlertsIndexPage.new
  @alertIndex.load
  expect(@alertIndex).to have_content(arg1)
end
