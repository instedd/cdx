class HomePage < CdxPageBase
  set_url '/'

  section :user_menu, "header .user" do
    element :icon, ".icon-user"
    element :logout, :link, "Log out"
  end

  section 'form', '#new_user' do
    element :user_name, '#user_email'
    element :password, '#user_password'
    element :login, '[name="commit"]'
  end
end
