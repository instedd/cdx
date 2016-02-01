class UserViewPage < CdxPageBase
  set_url '/users/{?query*}'

  element :invite_users, "a[title='Invite users']"

  def open_invite_users
    invite_users.trigger('click')
    modal = InviteUsersPage.new
    yield modal if block_given?
    modal
  end

end

class InviteUsersPage < CdxPageBase
  section :role, CdxSelect, ".modal label", text: /Role/i
  element :users, :field, "Users"

  element :primary, ".modal .btn-primary"
end
