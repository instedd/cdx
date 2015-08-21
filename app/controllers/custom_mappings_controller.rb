class CustomMappingsController < ApplicationController
  layout "institutions"
  set_institution_tab :devices

  before_filter :load_institution
  before_filter :load_device

  def index
    @custom_fields = @device.current_manifest.fields.select &:custom?
    @device.custom_mappings ||= {}
  end

  private

  def load_institution
    @institution = Institution.find params[:institution_id]
    authorize_resource(@institution, READ_INSTITUTION)
  end

  def load_device
    @device = @institution.devices.find params[:device_id]
    authorize_resource(@device, READ_DEVICE)
  end

end
