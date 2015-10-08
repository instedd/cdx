module DeviceModelsHelper

  include Policy::Actions

  def can_publish?(device_model)
    Policy.can?(PUBLISH_DEVICE_MODEL, device_model, current_user)
  end

  def can_unpublish?(device_model)
    Policy.can?(UNPUBLISH_DEVICE_MODEL, device_model, current_user) && device_model.devices.where.not(institution_id: device_model.institution_id).empty?
  end

end
