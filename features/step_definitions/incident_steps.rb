Then(/^the user should see no incidents$/) do
  @incidents = IncidentsPage.new
  @incidents.load

  within(@incidents.form) do |form|
    form.alert_group.set "Show all"
    form.select_date.set "Previous month"
  end
  expect(page).not_to have_xpath('//table/tr')
end
