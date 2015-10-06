module PolicyHelper
  def can?(action, resource)
    Policy.can?(action, resource, current_user)
  end
end
