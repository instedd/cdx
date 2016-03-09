class LocalizationHelper
  attr_accessor :time_zone # enforced time_zone to display times or nil to use default
  attr_accessor :locale # locale to format dates

  attr_accessor :timestamps_in_device_time_zone
  attr_accessor :devices_by_uuid

  def initialize(time_zone, locale, timestamps_in_device_time_zone)
    @time_zone = time_zone
    @locale = locale
    @timestamps_in_device_time_zone = timestamps_in_device_time_zone
  end

  # formats the value as the initialized time_zone (ie. the current_user time_zone)
  def format_datetime(value)
    format_datetime_time_zone(value, @time_zone)
  end

  # formats the value as the specified time_zone
  def format_datetime_time_zone(value, tz)
    return nil unless value

    value = Time.parse(value) unless value.is_a?(Time)
    value = value.in_time_zone(tz) if tz
    I18n.localize(value, locale: @locale, format: :long)
  end

  # formats the value as the device time_zone if timestamps_in_device_time_zone,
  # otherwise uses the initialized time_zone (ie. the current_user time_zone).
  def format_datetime_device(value, device_uuid)
    tz = nil

    if @timestamps_in_device_time_zone
      raise "devices_by_uuid cache for time formatting not initialized" unless @devices_by_uuid
      device = @devices_by_uuid[device_uuid]
      raise "Unable to find device in devices_by_uuid cache for time formatting" unless device
      tz = device.time_zone
    end

    tz ||= @time_zone

    format_datetime_time_zone(value, tz)
  end
end
