class CSVEventParser
  def apply_selector(selector, data)
    if (selector.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1 || selector.split(Manifest::PATH_SPLIT_TOKEN).size > 1
      raise "selector nesting is unsupported for CSV Events"
    else
      data[selector]
    end
  end

  def load_all(data)
    csv = CSV.new data
    headers = csv.shift
    csv.map do |row|
      result = Hash.new
      headers.each_with_index do |header, index|
        result[header] = row[index]
      end
      result
    end
  end

  def load(data)
    load_all(data).first
  end

  def dump(data)
    CSV.generate_line(data.keys) + CSV.generate_line(data.values)
  end

  def load_for_device data, device_key
    device = Device.includes(:manifests, :institution, :laboratories, :locations).find_by_secret_key(device_key)
    raw_events = load_all data
    events = raw_events.map do |raw_event|
      raw_event = dump raw_event
      Event.create_or_update_with device, raw_event
    end
    events.map do |event|
     {event: event[0].indexed_body, saved: event[1], errors: event[0].errors, index_failure_reason: event[0].index_failure_reason}
    end
  end
end
