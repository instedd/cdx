Then(/^the user should see no incidents$/) do
  @incidents = IncidentsPage.new
  @incidents.load

  within(@incidents.form) do |form|
    form.alertgroup.set "Show all"
    form.selectdate.set "Previous month"
  end
  expect(page).not_to have_xpath('//table/tr')
end
