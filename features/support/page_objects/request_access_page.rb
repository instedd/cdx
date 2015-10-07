class RequestAccessPage < SitePrism::Page
  set_url '/user/request_access'

  section 'form', '#new_user_request' do
    element :first_name, '#user_request_first_name'
    element :last_name, '#user_request_last_name'
    element :email, '#user_request_email'
    element :contact_number, '#user_request_contact_number'
    element :submit, '[name="commit"]'
  end
end
