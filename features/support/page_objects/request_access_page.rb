class RequestAccessPage < SitePrism::Page
  set_url '/user/request_access'

  section 'form', '#new_prospect' do
    element :first_name, '#prospect_first_name'
    element :last_name, '#prospect_last_name'
    element :email, '#prospect_email'
    element :contact_number, '#prospect_contact_number'
    element :submit, '[name="commit"]'
  end
end
