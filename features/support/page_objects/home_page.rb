class HomePage < CdxPageBase
  set_url '/'

  section 'form', '#new_user' do
    element :user_name, '#user_email'
    element :password, '#user_password'
    element :login, '[name="commit"]'
  end

  
end
