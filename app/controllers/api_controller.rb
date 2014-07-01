class ApiController < ActionController::Base
  include ApplicationHelper
  def create
    device = Device.includes(:manifests).includes(:institution).includes(:laboratories).includes(:locations).find_by_secret_key(params[:device_uuid])
    Event.create_or_update_with device, request.raw_post
    head :ok
  end

  def playground
    @devices = Device.all
  end
end
