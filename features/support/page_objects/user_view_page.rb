class UserViewPage < CdxPageBase
  set_url '/users/{?query*}'

  element :invite_users, "a[title='Invite users']"

  def open_invite_users(&block)
    invite_users.trigger('click')

    modal = UserInviteModal.new
    modal.select_new_user_option(&block)
  end
end

class UserInviteModal < CdxPageBase
  element :new_user_option, ".modal .invitation-option-card", text: "NEW USER"

  def select_new_user_option
    new_user_option.trigger('click')

    modal = InviteUsersModal.new
    yield modal if block_given?
    modal
  end
end

class InviteUsersModal < CdxPageBase
  section :role, CdxSelect, ".modal label", text: /Role/i
  element :add_user, :link, "Add"
  element :users, ".item-search input"

  element :primary, ".modal .btn-primary"
end
