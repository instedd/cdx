class LoginPage < SitePrism::Page
  set_url 'users/sign_in'

  section 'form', '#new_user' do
    element :user_name, '#user_email'
    element :password, '#user_password'
    element :login, '[name="commit"]'
  end
end
