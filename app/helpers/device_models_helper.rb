module DeviceModelsHelper

  include Policy::Actions

  def can_publish_device_model?(device_model)
    Policy.can?(PUBLISH_DEVICE_MODEL, device_model, current_user)
  end

  def can_unpublish_device_model?(device_model)
    Policy.can?(PUBLISH_DEVICE_MODEL, device_model, current_user) && device_model.devices.where.not(institution_id: device_model.institution_id).empty?
  end

  def can_delete_device_model?(device_model)
    !device_model.new_record? && !device_model.published? && Policy.can?(DELETE_DEVICE_MODEL, device_model, current_user)
  end

end
