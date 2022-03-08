class DeviceCommand < ApplicationRecord
  belongs_to :device

  def reply(data)
    case name
    when "send_logs"
      send_logs(data)
    end
    destroy
  end

  def send_logs(data)
    device.device_logs.create! message: data
  end
end
