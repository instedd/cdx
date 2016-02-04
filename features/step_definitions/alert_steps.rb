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
  @alert = NewAlertPage.new
  @alert.load

  within(@alert.form) do |form|
    form.name.set arg1
    form.description.set 'aaaaa'
    form.message.set 'bbb'
    form.submit.click
  end
end



Given(/^the user creates a new error category alert with all fields with name "(.*?)"$/) do |arg1|
  site = @navigation_context.entity.sites.make
  device = site.devices.make

  @alert = NewAlertPage.new
  @alert.load

  within(@alert.form) do |form|
    form.name.set arg1
    form.description.set 'aaaaa'
    form.message.set 'web msg'
    form.smsmessage.set 'sms msg'
    form.smslimit.set 2

    #Note: this did not work due to the CSS for 'radio': form.choose 'device_errors'
    find('label[for=device_errors]').click

    form.device_errors_value.set 2

    form.sites.set_exact_multi "Mrs. Terry Goyette"

    form.devices.set_exact_multi "Mr. Alphonso Witting"

    form.roles.set_exact_multi "Institution Aric Smith Reader"

    form.internal_users.set_exact_multi @user.email

    form.aggregation.set "aggregated"
    form.aggregation_frequency.set "day"

    form.channel.set_exact "sms"

    form.externaluser_firstname.set 'bob'
    form.externaluser_lastname.set 'smith'
    form.externaluser_email.set 'aa@bb.com'
    form.externaluser_telephone.set '1234567'
    form.new_externaluser.click

    form.submit.click
  end
end


Given(/^the user creates a new anomalie category alert with all fields with name "(.*?)"$/) do |arg1|

  site = @navigation_context.entity.sites.make
  device = site.devices.make

  @alert = NewAlertPage.new
  @alert.load

  within(@alert.form) do |form|
    form.name.set arg1
    form.description.set 'aaaaa'
    form.message.set 'web msg'
    form.smsmessage.set 'sms msg'
    form.smslimit.set 2

    #Note: this did not work due to the CSS for 'radio': form.choose 'anomalies'
    find('label[for=anomalies]').click

    form.anomalies.set "missing_start_time"
    form.sites.set_exact_multi "Mrs. Terry Goyette"
    form.devices.set_exact_multi "Mr. Alphonso Witting"
    form.roles.set_exact_multi "Institution Aric Smith Reader"
    form.internal_users.set_exact_multi @user.email
    form.aggregation.set "aggregated"
    form.aggregation_frequency.set "day"
    form.channel.set_exact "sms"
    form.externaluser_firstname.set 'bob'
    form.externaluser_lastname.set 'smith'
    form.externaluser_email.set 'aa@bb.com'
    form.externaluser_telephone.set '1234567'
    form.new_externaluser.click

    form.submit.click
  end
end

Given(/^the user creates a new testresult alert with all fields with name "(.*?)"$/) do |arg1|

  site = @navigation_context.entity.sites.make
  device = site.devices.make

  @alert = NewAlertPage.new
  @alert.load

  within(@alert.form) do |form|
    form.name.set arg1
    form.description.set 'aaaaa'
    form.message.set 'web msg'
    form.smsmessage.set 'sms msg'
    form.smslimit.set 2

    find('label[for=test_results]').click
    form.sites.set_exact_multi "Mrs. Terry Goyette"
    form.devices.set_exact_multi "Mr. Alphonso Witting"
    form.roles.set_exact_multi "Institution Aric Smith Reader"
    form.internal_users.set_exact_multi @user.email
    form.aggregation.set "aggregated"
    form.aggregation_frequency.set "day"
    form.aggregationthresholdlimit.set 5
    form.channel.set_exact "sms"
    form.externaluser_firstname.set 'bob'
    form.externaluser_lastname.set 'smith'
    form.externaluser_email.set 'aa@bb.com'
    form.externaluser_telephone.set '1234567'
    
    form.conditions.set_exact_multi "mtb"
    form.condition_results.set_exact_multi "positive"
    
    form.new_externaluser.click

    form.submit.click
  end
end

Then (/^the user should see in list alerts "(.*?)"$/) do |arg1|
  @alertIndex = AlertsIndexPage.new
  @alertIndex.load
  expect(@alertIndex).to have_content(arg1)
end


Then (/^the user should click edit "(.*?)"$/) do |arg1|
  @alertIndex = AlertsIndexPage.new
  @alertIndex.load
  click_link(arg1)
end

And (/^the user should view edit page "(.*?)"$/) do |arg1|
  find_field('alertname').value.should eq arg1
end


Then (/^delete the alert$/) do
  click_link("delete_alert")

  # To click on the modal confirm, had to use the line below:
  find('.btn-danger').click
end


Then (/^the user should not see in list alerts "(.*?)"$/) do |arg1|
  @alertIndex = AlertsIndexPage.new
  @alertIndex.load
  expect(@alertIndex).not_to have_content(arg1)
end