module Cdx::Api::LocalTimeZoneConversion

  # Parses a string value, converting its timezone to the local timezone, if it represents
  # a date, or leaving it as is, otherwise.
  def convert_timezone_if_date(string_value)
    return string_value unless (Time.zone rescue nil)

    Integer(string_value) rescue (convert_timezone(string_value) || string_value)
  end

  def convert_timezone(date_string)
    Time.zone.parse(date_string).try(&:iso8601)
  end

end