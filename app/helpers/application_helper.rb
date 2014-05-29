module ApplicationHelper
  def has_access?(resource, action)
    result = Policy.check_all(action, resource, @current_user_policies, current_user)
    !!result
  end
end
