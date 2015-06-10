# Ensure DeviceMessage class is loaded first from app/models before reopening it to ensure its super class is properly set
DeviceMessage; class DeviceMessage
  def self.create_and_process(params = {})
    device_message = self.make params
    if device_message.index_failed?
      raise 'DeviceMessage index failed'
    else
      device_message.process
    end
    device_message
  end
end
