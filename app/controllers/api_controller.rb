class ApiController < ActionController::Base
  include ApplicationHelper
  def create
    device = Device.includes(:manifests).find_by_secret_key(params[:device_uuid])
    Event.create device: device, raw_data: request.raw_post
    head :ok
  end

  def playground
    @devices = Device.all
  end
end
