class DeviceCommandsController < ApplicationController
  before_filter :load_device

  skip_before_filter :verify_authenticity_token
  skip_before_filter :authenticate_user!

  def index
    commands = @device.device_commands.map do |command|
      obj = {
        id: command.id,
        name: command.name
      }
      obj.merge!(JSON.parse(command.command)) if command.command.present?
      obj
    end

    render json: commands
  end

  def reply
    command = @device.device_commands.find params[:id]
    command.reply(request.raw_post)
    head :ok
  end

  private

  def load_device
    @device = Device.find_by_uuid params[:device_id]
    unless @device
      return head(:not_found)
    end

    unless @device.validate_authentication(params[:key])
      return head(:forbidden)
    end

  end
end
