class ManifestFieldMapping
  include DateDistanceHelper

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

    check_op(node, "lookup") do |value|
      return lookup(value, data)
    end

    check_op(node, "case") do |value, cases|
      return case_(traverse(value, data), cases, data)
    end

    check_op(node, "lowercase") do |value|
      return lowercase(traverse(value, data))
    end

    check_op(node, "concat") do |value|
      return concat(value, data)
    end

    check_op(node, "strip") do |value|
      return strip(traverse(value, data))
    end

    check_op(node, "convert_time") do |interval, source_unit, desired_unit|
      return convert_time(traverse(interval, data), traverse(source_unit, data), traverse(desired_unit, data))
    end

    check_op(node, "beginning_of") do |date_time, time_unit|
      return beginning_of(traverse(date_time, data), traverse(time_unit, data))
    end

    check_op(node, "duration") do |components|
      return duration_field(components, data)
    end

    # TODO: Refactor this
    check_op(node, "years_between") do |first_date, second_date|
     return years_between(traverse(first_date, data), traverse(second_date, data))
    end

    check_op(node, "months_between") do |first_date, second_date|
     return months_between(traverse(first_date, data), traverse(second_date, data))
    end

    check_op(node, "days_between") do |first_date, second_date|
     return days_between(traverse(first_date, data), traverse(second_date, data))
    end

    check_op(node, "hours_between") do |first_date, second_date|
     return hours_between(traverse(first_date, data), traverse(second_date, data))
    end

    check_op(node, "minutes_between") do |first_date, second_date|
     return minutes_between(traverse(first_date, data), traverse(second_date, data))
    end

    check_op(node, "seconds_between") do |first_date, second_date|
     return seconds_between(traverse(first_date, data), traverse(second_date, data))
    end

    check_op(node, "milliseconds_between") do |first_date, second_date|
     return milliseconds_between(traverse(first_date, data), traverse(second_date, data))
    end

    check_op(node, "clusterise") do |number, interval_stops|
      return clusterise(traverse(number, data), interval_stops)
    end

    check_op(node, "substring") do |value, from, to|
      return traverse(value, data)[from..to]
    end

    check_op(node, "map") do |collection_lookup, mapping|
      return map(traverse(collection_lookup, data), mapping)
    end

    check_op(node, "parse_date") do |date, format|
      return parse_date(node, data, traverse(date, data), traverse(format, data))
    end

    check_op(node, "hash") do |value|
      value = traverse(value, data)
      return unless value
      return MessageEncryption.hash value
    end

    check_op(node, "if") do |cond, then_body, else_body|
      condition = traverse(cond, data)
      return traverse(condition ? then_body : else_body, data)
    end

    check_op(node, "equals") do |left, right|
      return traverse(left, data) == traverse(right, data)
    end

    check_op(node, "script") do |script|
      return run_script(script, data)
    end

    node.to_s
  end

  def check_op(node, name)
    if node.is_a?(Hash) && (value = node[name].presence)
      yield value
    end
  end

  def run_script(script, data)
    ctx = V8::Context.new
    begin
      ctx["message"] = data

      if @device
        ctx["device"] = script_device(@device)
        if site = @device.site
          ctx["site"] = script_site(site)
        end
        if location = site.try(&:location)
          ctx["location"] = script_location(location)
        end
      end

      result = ctx.eval(script)
      result = to_ruby(result)
      result
    rescue V8::Error => e
      raise ManifestParsingError.script_error(@field.target_field, e.message)
    ensure
      ctx.dispose
    end
  end

  def to_ruby(v8_object)
    case v8_object
    when V8::Array
      array = v8_object.to_a
      array.map! { |elem| to_ruby(elem) }
    when V8::Object
      hash = v8_object.to_h
      hash.each do |key, value|
        hash[key] = to_ruby(value)
      end
    else
      v8_object
    end
  end

  def script_device(device)
    {
      uuid: device.uuid,
      name: device.name,
    }
  end

  def script_site(site)
    {
      name: site.name,
      address: site.address,
      city: site.city,
      state: site.state,
      zip_code: site.zip_code,
      country: site.country,
      region: site.region,
      lat: site.lat,
      lng: site.lng,
      location_geoid: site.location_geoid,
    }
  end

  def script_location(location)
    {
      name: location.name,
      lat: location.lat,
      lng: location.lng,
    }
  end

  def lookup(path, data)
    @manifest.parser.lookup(path, data, @root)
  end

  def case_(value, mappings, data)
    return value unless value
    if value.is_an? Array
      value.map do |value|
        case_ value, mappings, data
      end
    else
      else_mapping = nil

      mappings.each do |mapping|
        else_mapping ||= mapping["else"]
        if (when_value = mapping["when"]) && value.match(when_value.gsub("*", ".*"))
          return traverse(mapping["then"], data)
        end
      end

      unless else_mapping
        raise ManifestParsingError.invalid_mapping(value, @field.target_field, mappings)
      end

      traverse(else_mapping, data)
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

  def parse_date(node, data, date, format)
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

  def duration_field(components, data)
    Hash[
      components.map do |key, value|
        [key, traverse(value, data).to_i]
      end
    ]
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
      return "<#{interval_stops[0]}"  if number < interval_stops.first
      interval_stops.each_with_index do |stop, index|
        if number.between? stop, interval_stops[index + 1 ]
          return "#{stop}-#{interval_stops[index+1]}"
        end
      end
    end
  end

  def coerce_values value
    if @field.type == 'integer' &&  ManifestFieldValidation.is_an_integer?(value)
      if value.is_a? Array
        value.map do |value|
          value && value.to_i
        end
      else
        value.to_i
      end
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

  def map(values, mapping)
    return traverse(mapping, values) unless values.is_a? Array
    values.map do |value|
      traverse(mapping, value)
    end
  end
end
