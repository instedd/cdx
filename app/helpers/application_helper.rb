module ApplicationHelper
  def has_access?(resource, action)
    !!check_access(resource, action)
  end

  def check_access(resource, action)
    Policy.authorize(action, resource, current_user, @current_user_policies)
  end
end
