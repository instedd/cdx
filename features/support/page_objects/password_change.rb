class PasswordChange < SitePrism::Page
  set_url '/users/password_expired'

  section 'form', '#edit_user' do
    element :current_password, '#user_current_password'
    element :new_password, '#user_password'
    element :confirm_password, '#user_password_confirmation'
    element :submit, '[name="commit"]'
  end
end

class AcceptInvitiation < CdxPageBase
  set_url '/users/invitation/accept{?query*}'

  element :password, :field, 'Password'
  element :password_confirmation, :field, 'Password confirmation'
  element :primary, '[value="Set my password"]'
end
