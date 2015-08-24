class CustomMappingsController < ApplicationController
  before_filter :load_device

  def index
    @custom_fields = @device.current_manifest.fields.select &:custom?
    @device.custom_mappings ||= {}
  end

  private

  def load_device
    @device = Device.find params[:device_id]
    authorize_resource(@device, READ_DEVICE)
  end

end
