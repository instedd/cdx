class ManifestFieldMapping
  def initialize(manifest, field, device)
    @manifest = manifest
    @field = field
    @device = device
  end

  def apply_to(data)
    coerce_values(traverse @field["source"], data)
  end

  def traverse node, data
    return nil if node.nil?

    if node["lookup"].present?
      return lookup(node["lookup"], data)
    end

    if node["map"].present?
      return map(traverse(node["map"][0], data), node["map"][1])
    end

    if node["lowercase"].present?
      return traverse(node["lowercase"], data).downcase
    end

    if node["concat"].present?
      return node["concat"].map do |source|
        traverse(source, data)
      end.join
    end

    if node["strip"].present?
      return traverse(node["strip"], data).strip
    end

    if node["convert_time"].present?
      return convert_time(traverse(node["convert_time"][0], data), traverse(node["convert_time"][1], data), traverse(node["convert_time"][2], data))
    end

    if node["beginning_of"].present?
      return beginning_of(traverse(node["beginning_of"][0], data), traverse(node["beginning_of"][1], data))
    end

    # TODO: Refactor this
    if node["years_between"].present?
     return years_between(traverse(node["years_between"][0], data), traverse(node["years_between"][1], data))
    end

    if node["months_between"].present?
     return months_between(traverse(node["months_between"][0], data), traverse(node["months_between"][1], data))
    end

    if node["days_between"].present?
     return days_between(traverse(node["days_between"][0], data), traverse(node["days_between"][1], data))
    end

    if node["hours_between"].present?
     return hours_between(traverse(node["hours_between"][0], data), traverse(node["hours_between"][1], data))
    end

    if node["minutes_between"].present?
     return minutes_between(traverse(node["minutes_between"][0], data), traverse(node["minutes_between"][1], data))
    end

    if node["seconds_between"].present?
     return seconds_between(traverse(node["seconds_between"][0], data), traverse(node["seconds_between"][1], data))
    end

    if node["milliseconds_between"].present?
     return milliseconds_between(traverse(node["milliseconds_between"][0], data), traverse(node["milliseconds_between"][1], data))
    end

    if node["clusterise"].present?
      return clusterise(traverse(node["clusterise"][0], data), node["clusterise"][1])
    end

    if node["substring"].present?
      return traverse(node["substring"][0], data)[node["substring"][1]..node["substring"][2]]
    end

    if node["parse_date"].present?
      return parse_date(node, data)
    end

    if node["hash"].present?
      value = traverse(node["hash"], data)
      return unless value
      return EventEncryption.hash value
    end

    if node["if"].present?
      condition = traverse(node["if"][0], data)
      if condition
        return traverse(node["if"][1], data)
      else
        return traverse(node["if"][2], data)
      end
    end

    if node["equals"].present?
      return traverse(node["equals"][0], data) == traverse(node["equals"][1], data)
    end

    if node["script"].present?
      return run_script(node["script"], data)
    end

    node.to_s
  end

  def run_script(script, data)
    ctx = V8::Context.new
    begin
      ctx["event"] = data
      ctx.eval(script)
    ensure
      ctx.dispose
    end
  end

  def map(value, mappings)
    return value unless value
    if value.is_an? Array
      value.map do |value|
        map value, mappings
      end
    else
      mapping = mappings.detect do |mapping|
        value.match mapping["match"].gsub("*", ".*")
      end

      raise ManifestParsingError.invalid_mapping(value, @field['target_field'], mappings) unless mapping

      mapping["output"]
    end
  end

  def lookup(path, data)
    @manifest.parser.lookup(path, data)
  end

  def parse_date(node, data)
    format = traverse(node["parse_date"][1], data)
    date = traverse(node["parse_date"][0], data)
    parsed_date = DateTime.strptime(date, format)
    if !format.match(/%[zZ]/) && @device.try(:time_zone)
      parsed_date = ActiveSupport::TimeZone[@device.time_zone].local(parsed_date.year, parsed_date.month, parsed_date.day, parsed_date.hour, parsed_date.minute, parsed_date.second)
    end
    parsed_date
  end

  def beginning_of(date_time, time_unit)
    date_time = DateTime.parse(date_time.to_s) # to ensure we have a date_time and not a string

    case time_unit
    when "day"
      date_time.beginning_of_day
    when "hour"
      date_time.beginning_of_hour
    when "minute"
      date_time.beginning_of_minute
    when "month"
      date_time.beginning_of_month
    when "week"
      date_time.beginning_of_week
    when "year"
      date_time.beginning_of_year
    else
      raise ManifestParsingError.unsupported_time_unit(time_unit, @field['target_field'])
    end
  end

  def years_between(first_date, second_date)
    second_date = DateTime.parse(second_date.to_s)
    first_date = DateTime.parse(first_date.to_s)
    years = (second_date.year - first_date.year)
    if second_date.month == first_date.month
      years + (second_date.day >= first_date.day ? 0 : 1)
    else
      years + (second_date.month >= first_date.month ? 0 : 1)
    end
  end

  def months_between(first_date, second_date)
    second_date = DateTime.parse(second_date.to_s)
    first_date = DateTime.parse(first_date.to_s)
    (second_date.year - first_date.year) * 12 + second_date.month - first_date.month - (second_date.day >= first_date.day ? 0 : 1)
  end

  def days_between(first_date, second_date)
    distance_between(first_date, second_date).to_i
  end

  def hours_between(first_date, second_date)
    (distance_between(first_date, second_date) * 24).to_i
  end

  def minutes_between(first_date, second_date)
    (distance_between(first_date, second_date) * 1440).to_i
  end

  def seconds_between(first_date, second_date)
    (distance_between(first_date, second_date) * 86400).to_i
  end

  def milliseconds_between(first_date, second_date)
    (distance_between(first_date, second_date) * 86400000000).to_i
  end

  def distance_between(first_date, second_date)
    second_date = DateTime.parse(second_date.to_s)
    first_date = DateTime.parse(first_date.to_s)
    (second_date - first_date).abs
  end

  def convert_time(time_interval, source_unit, desired_unit)
    time_interval = time_interval.to_f

    time_interval = case source_unit
    when "years"
      time_interval.years
    when "months"
      time_interval.months
    when "days"
      time_interval.days
    when "hours"
      time_interval.hours
    when "minutes"
      time_interval.minutes
    when "seconds"
      time_interval.seconds
    when "milliseconds"
      (time_interval / 1000000).seconds
    else
      raise ManifestParsingError.unsupported_time_unit(source_unit, @field['target_field'])
    end

    case desired_unit
    when "years"
      time_interval / 1.year
    when "months"
      time_interval / 1.month
    when "days"
      time_interval / 1.day
    when "hours"
      time_interval / 1.hour
    when "minutes"
      time_interval / 1.minute
    when "seconds"
      time_interval
    when "milliseconds"
      time_interval * 1000000
    else
      raise ManifestParsingError.unsupported_time_unit(desired_unit, @field['target_field'])
    end
  end

  def clusterise(number, interval_stops)
    number = number.to_f
    interval_stops = interval_stops.map &:to_i
    return "#{interval_stops.last}+" if number > interval_stops.last
    return "0-#{interval_stops[0]}"  if number.between? 0, interval_stops[0]
    interval_stops.each_with_index do |stop, index|
      if number.between? stop, interval_stops[index + 1 ]
        return "#{stop}-#{interval_stops[index+1]}"
      end
    end
  end

  def coerce_values value
    if @field['type'] == 'integer' &&  ManifestFieldValidation.is_an_integer?(value)
      value.to_i
    else
      value
    end
  end
end
