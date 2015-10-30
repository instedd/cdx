class InvitePage < SitePrism::Page
  set_url '/users/invitation/new'

  section 'form', '#new_user' do
    element :email, '#user_email'
    element :invite, '[name="commit"]'
  end
end
