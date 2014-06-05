module ApplicationHelper
  def has_access?(resource, action)
    !!check_access(resource, action)
  end

  def check_access(resource, action)
    Policy.check_all(action, resource, @current_user_policies, current_user)
  end
end
