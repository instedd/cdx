module PolicyHelper
  def can?(action, resource)
    Policy.can?(action, resource, current_user)
  end

  def authorize(action, resource)
    Policy.authorize(action, resource, current_user)
  end

  def can_index_laboratories?
    can?(Policy::Actions::CREATE_INSTITUTION_LABORATORY, Institution) || authorize(Policy::Actions::READ_LABORATORY, Laboratory).exists?
  end

  def can_index_devices?
    can?(Policy::Actions::REGISTER_INSTITUTION_DEVICE, Institution) || authorize(Policy::Actions::READ_DEVICE, Device).exists?
  end

  def can_index_device_models?
    can?(Policy::Actions::REGISTER_INSTITUTION_DEVICE_MODEL, Institution) || authorize(Policy::Actions::READ_DEVICE_MODEL, DeviceModel).exists?
  end
end
