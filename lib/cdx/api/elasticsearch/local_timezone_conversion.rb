module Cdx::Api::LocalTimeZoneConversion

  # Parses a string value, converting its timezone to the local timezone, if it represents
  # a date, or leaving it as is, otherwise.
  def convert_timezone_if_date(string_value)
    if timezone_available? && !is_integer?(string_value)
      convert_timezone(string_value) || string_value
    else
      string_value
    end
  end

  def convert_timezone(date_string)
    Time.zone.parse(date_string).try(&:iso8601)
  end

  private

  def timezone_available?
    Time.zone rescue false
  end

  def is_integer?(val)
    Integer(val) rescue false
  end
end