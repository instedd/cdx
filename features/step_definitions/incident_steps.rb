Then(/^the user should see no incidents$/) do
  @incidents = IncidentsPage.new
  @incidents.load

  expect(page).not_to have_xpath('//table/tr')
end
