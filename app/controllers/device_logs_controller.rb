class DeviceLogsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:create]
  skip_before_filter :authenticate_user!, only: [:create]

  def create
    device = Device.find_by_uuid params[:device_id]
    return head(:not_found) unless device

    device.device_logs.create! message: request.raw_post

    head :ok
  end
end
