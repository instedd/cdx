# Ensure DeviceEvent class is loaded first from app/models before reopening it to ensure its super class is properly set
DeviceEvent; class DeviceEvent
  def self.create_and_process(params = {})
    device_event = self.make params
    if device_event.index_failed?
      raise 'DeviceEvent index failed'
    else
      device_event.process
    end
    device_event
  end
end
