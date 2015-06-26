class ManifestFieldMapping
  include ActionView::Helpers::DateHelper

  def initialize(manifest, field, device, data)
    @manifest = manifest
    @field = field
    @device = device
    @root = data
  end

  def apply
    coerce_values(traverse @field.source, @root)
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
      return lowercase(traverse(node["lowercase"], data))
    end

    if node["concat"].present?
      return concat(node["concat"], data)
    end

    if node["strip"].present?
      return strip(traverse(node["strip"], data))
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

    if node["collect"].present?
      collection_lookup, mapping = node["collect"].first, node["collect"].second
      return collect(traverse(collection_lookup, data), mapping)
    end

    if node["parse_date"].present?
      return parse_date(node, data)
    end

    if node["hash"].present?
      value = traverse(node["hash"], data)
      return unless value
      return MessageEncryption.hash value
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
      ctx["message"] = data
      ctx["device"] = { uuid: @device.uuid, name: @device.name } if @device

      result = ctx.eval(script)

      if result.is_a? V8::Array
        result = result.to_a
      elsif result.is_a? V8::Object
        raise ManifestParsingError.invalid_script(@field.target_field)
      end
      result
    rescue V8::Error => e
      raise ManifestParsingError.script_error(@field.target_field, e.message)
    ensure
      ctx.dispose
    end
  end

  def lookup(path, data)
    @manifest.parser.lookup(path, data, @root)
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

      raise ManifestParsingError.invalid_mapping(value, @field.target_field, mappings) unless mapping

      mapping["output"]
    end
  end

  def lowercase(value)
    return unless value
    if value.is_a? Array
      value.map do |value|
        lowercase value
      end
    else
      value.downcase
    end
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
      raise ManifestParsingError.unsupported_time_unit(time_unit, @field.target_field)
    end
  end

  def years_between(first_date, second_date)
    distance_between(first_date, second_date, :years)
  end

  def months_between(first_date, second_date)
    distance_between(first_date, second_date, :months)
  end

  def days_between(first_date, second_date)
    distance_between(first_date, second_date, :days)
  end

  def hours_between(first_date, second_date)
    distance_between(first_date, second_date, :hours)
  end

  def minutes_between(first_date, second_date)
    distance_between(first_date, second_date, :minutes)
  end

  def seconds_between(first_date, second_date)
    distance_between(first_date, second_date, :seconds)
  end

  def milliseconds_between(first_date, second_date)
    seconds_between(first_date, second_date) * 1000
  end

  def distance_between(first_date, second_date, unit)
    second_date = DateTime.parse(second_date.to_s)
    first_date = DateTime.parse(first_date.to_s)
    distance_of_time_in_words_hash(first_date, second_date, accumulate_on: unit)[unit]
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
      raise ManifestParsingError.unsupported_time_unit(source_unit, @field.target_field)
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
      raise ManifestParsingError.unsupported_time_unit(desired_unit, @field.target_field)
    end
  end

  def clusterise(number, interval_stops)
    return nil if number.nil?
    if number.is_a? Array
      number.map {|num| clusterise(num, interval_stops)}
    else
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
  end

  def coerce_values value
    if @field.type == 'integer' &&  ManifestFieldValidation.is_an_integer?(value)
      value.to_i
    else
      value
    end
  end

  def concat(values, data)
    return values.map do |source|
      value = traverse(source, data)
      raise "Can't concat array values - use collect instead" if value.is_a? Array
      value
    end.join
  end

  def strip(values)
    return nil if values.nil?
    if values.is_a? Array
      values.map {|value| strip(value)}
    else
      values.strip
    end
  end

  def collect(values, mapping)
    return traverse(mapping, values) unless values.is_a? Array
    values.map do |value|
      traverse(mapping, value)
    end
  end
end
