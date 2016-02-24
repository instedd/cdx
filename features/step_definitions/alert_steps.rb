include AlertsHelper

Given(/^the user has an account$/) do
  @user = User.make(password: '12345678', first_name: 'Bob', email: 'zaa1aa@ggg.com')
  @institution = Institution.make user_id: @user.id
  @user.grant_superadmin_policy
  authenticate(@user)

  #needed for the @sites
  default_params =  {context: @institution.uuid}
  @navigation_context = NavigationContext.new(@user, default_params[:context])
end


Given(/^the user creates a new error category alert with all fields with name "(.*?)"$/) do |arg1|
  site = @navigation_context.entity.sites.make
  device = site.devices.make
  @alert = NewAlertPage.new
  @alert.load

  within(@alert.form) do |form|
    alert_form_fillin_basic(form, arg1)
    
    #Note: this did not work due to the CSS for 'radio': form.choose 'device_errors'
    find('label[for=device_errors]').click
    
    form.device_errors_value.set 2
    form.sites.set_exact_multi "Mrs. Terry Goyette"
    form.devices.set_exact_multi "Mr. Alphonso Witting"
    form.roles.set_exact_multi "Institution Aric Smith Reader"
    form.internal_users.set_exact_multi @user.email
    form.aggregation.set "record"
    form.channel.set_exact "email"
    form.emaillimit.set 2
    alert_form_fillin_externaluser(form)
    form.new_externaluser.click
 #   form.submit.click
     find_button("submit").trigger('click')
  end
  
end


Given(/^the user creates a new anomalie category alert with all fields with name "(.*?)"$/) do |arg1|
  site = @navigation_context.entity.sites.make
  device = site.devices.make

  @alert = NewAlertPage.new
  @alert.load

  within(@alert.form) do |form|
    alert_form_fillin_basic(form, arg1)

    #Note: this did not work due to the CSS for 'radio': form.choose 'anomalies'
    find('label[for=anomalies]').click
    
    form.anomalies.set "missing_sample_id"
    form.sites.set_exact_multi "Mrs. Terry Goyette"
    form.devices.set_exact_multi "Mr. Alphonso Witting"
    form.roles.set_exact_multi "Institution Aric Smith Reader"
    form.internal_users.set_exact_multi @user.email
    form.aggregation.set "record"
    form.channel.set_exact "email"
    alert_form_fillin_externaluser(form)
    form.new_externaluser.click

    find_button("submit").trigger('click')
  end
end


Given(/^the user creates a new testresult alert with all fields with name "(.*?)"$/) do |arg1|
  site = @navigation_context.entity.sites.make
  device = site.devices.make

  @alert = NewAlertPage.new
  @alert.load

  within(@alert.form) do |form|
    alert_form_fillin_basic(form, arg1)

    find('label[for=test_results]').click
    
    form.sites.set_exact_multi "Mrs. Terry Goyette"
    form.devices.set_exact_multi "Mr. Alphonso Witting"
    form.roles.set_exact_multi "Institution Aric Smith Reader"
    form.internal_users.set_exact_multi @user.email
    form.aggregation.set "aggregated"
    form.aggregation_frequency.set "day"
    form.aggregationthresholdlimit.set 5
    form.channel.set_exact "sms"
    alert_form_fillin_externaluser(form)

    form.conditions.set_exact_multi "mtb"
    form.condition_results.set_exact_multi "positive"

    form.new_externaluser.click
    #  form.submit.click
    find_button("submit").trigger('click')
  end
end

Given(/^the user Successful creates a new utilization efficiency category with all fields with name "(.*?)"$/) do |arg1|
  site = @navigation_context.entity.sites.make
  device = site.devices.make

  @alert = NewAlertPage.new
  @alert.load

  within(@alert.form) do |form|
    alert_form_fillin_basic(form, arg1)
    
    find('label[for=utilization_efficiency]').click
    form.sites.set_exact_multi "Mrs. Terry Goyette"
    form.devices.set_exact_multi "Mr. Alphonso Witting"
    form.roles.set_exact_multi "Institution Aric Smith Reader"
    form.internal_users.set_exact_multi @user.email
    form.aggregation_frequency.set "day"
    form.aggregationthresholdlimit.set 5
    form.channel.set_exact "sms"
    alert_form_fillin_externaluser(form)
    form.timespan.set 5
    form.sampleid.set 'ABC'

    form.new_externaluser.click
    # form.submit.click
    find_button("submit").trigger('click')
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


Then (/^the user should have error_code alert result$/) do
  parent_location = Location.make
  leaf_location1 = Location.make parent: parent_location
  upper_leaf_location = Location.make

  before_test_history_count = AlertHistory.count
  site1 = Site.make institution: @institution, location_geoid: leaf_location1.id
  device1 = Device.make institution: @institution, site: site1

  #note: make sure the test above using thise does not have sample-id set, and aggregation type = record
  DeviceMessage.create_and_process device: device1, plain_text_data: (Oj.dump test:{assays:[result: :negative], error_code: 2}, sample: {id: 'a'}, patient: {id: 'a',gender: :male})
  after_test_history_count = AlertHistory.count
  
  expect(after_test_history_count).to be > before_test_history_count
end


Then (/^the user should have no_sample_id alert result$/) do
  parent_location = Location.make
  leaf_location1 = Location.make parent: parent_location
  upper_leaf_location = Location.make

  before_test_history_count = AlertHistory.count
  site1 = Site.make institution: @institution, location_geoid: leaf_location1.id
  device1 = Device.make institution: @institution, site: site1

  #note: make sure the test above using thise does not have sample-id set, and aggregation type = record
  DeviceMessage.create_and_process device: device1, plain_text_data: (Oj.dump test:{assays:[result: :negative]}, sample: {}, patient: {id: 'a',gender: :male})
  after_test_history_count = AlertHistory.count
 
  expect(before_test_history_count+1).to eq(after_test_history_count)
end


Then (/^the user should have an incident$/) do
  @incidents = IncidentsPage.new
  @incidents.load
  expect(page).to have_xpath('//table/tbody/tr', :count => 1)
end


Then (/^the user should see no edit alert incidents$/) do
  expect(page).to have_css('div#incidents', :text => 'NEVER')
end


Then (/^the user should have two emails$/) do
  after_test_notification_count = RecipientNotificationHistory.count
  after_test_history_count = AlertHistory.count
   expect(after_test_notification_count).to eq(2)
end
