class EditAlertPage < SitePrism::Page
  set_url '/alerts/{id}/edit'

  section 'form', '#new_alert' do
    element :name, '#alertname'

    element :submit, '#submit'

    element :delete, '#delete_alert'
  end
end
