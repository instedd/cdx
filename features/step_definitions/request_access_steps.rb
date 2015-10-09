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
  @first_name, @last_name = prospect_name.split(' ')
end

Given(/^Bill Smith does not have an account$/) do
  visit_request_access_page
end

When(/^he provides the correct information$/) do
  within_section(@request_access.form) do |section|
    section.first_name.set @first_name
    section.last_name.set @last_name
    section.email.set Faker::Internet.email
    section.contact_number.set Faker::PhoneNumber.phone_number
    section.submit.click
  end
end

Then(/^Bill should see "(.*?)"$/) do |arg1|
  page.should have_content(arg1)
end

Given(/^the following pending requests for access$/) do |table|
  @access_requests = []
  table.hashes.each do |hash|
    @access_requests << UserRequest.make(hash)
  end
end

When(/^Bob visits the Prospects page$/) do
  @prospects_page = ProspectsPage.new
  @prospects_page.load
end

Then(/^Bob should see the requests awaiting approval$/) do
  within_section(@prospects_page.results) do |results|
    expect(results.rows.size).to eq(2)
    first_names = results.all('tr td:nth-child(1)').map(&:text)
    last_names = results.all('tr td:nth-child(2)').map(&:text)
    emails = results.all('tr td:nth-child(3)').map(&:text)
    @access_requests.each_with_index.map do |request, index|
      expect(first_names).to include(request.first_name)
      expect(last_names).to include(request.last_name)
      expect(emails).to include(request.email)
    end
  end
end
