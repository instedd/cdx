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

  def try_edit_device_model_path(device_model)
    if @updateable_device_model_ids.include?(device_model.id) && (!device_model.published? || @publishable_device_model_ids.include?(device_model.id))
      edit_device_model_path(device_model)
    else
      device_model_path(device_model)
    end
  end

end
