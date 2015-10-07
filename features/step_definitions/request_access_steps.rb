def visit_request_access_page
  @request_access ||= RequestAccessPage.new
  @request_access.load
end

Given(/^an administrator called "(.*?)"$/) do |name|
  @administrator = User.make
end

Given(/^an institution name "(.*?)"$/) do |institution|
  @institution = Institution.make(user_id: @administrator.id)
end

Given(/^a prospect named "(.*?)"$/) do |prospect_name|
  NewProspect = Struct.new(:first_name, :last_name, :email, :contact_number, :comments)
  first_name, last_name = prospect_name.split(' ')
  email = Faker::Internet.email
  contact_number = Faker::PhoneNumber.phone_number
  comments = Faker::Lorem.paragraph
  @prospect = NewProspect.new(first_name, last_name, email, contact_number, comments)
end

Given(/^Bill Smith does not have an account$/) do
  visit_request_access_page
end

When(/^he provides the correct information$/) do
  within_section(@request_access.form) do |section|
    section.first_name.set @prospect.first_name
    section.last_name.set @prospect.last_name
    section.email.set @prospect.email
    section.contact_number.set @prospect.contact_number
    section.submit.click
  end
end

Then(/^Bill should see "(.*?)"$/) do |arg1|
  page.should have_content(arg1)
end
