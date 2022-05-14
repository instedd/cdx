class UserViewPage < CdxPageBase
  set_url '/users/{?query*}'

  element :invite_users, "a[title='Invite users']"

  def open_invite_users(&block)
    invite_users.click

    modal = UserInviteModal.new
    modal.select_new_user_option(&block)
  end
end

class UserInviteModal < CdxPageBase

  def select_new_user_option
    modal = InviteUsersModal.new
    yield modal if block_given?
    modal
  end
end

class InviteUsersModal < CdxPageBase
  section :role, CdxSelect, ".modal label", text: /Role/i
  element :users, ".item-search input"

  element :primary, ".modal .btn-primary"
end
