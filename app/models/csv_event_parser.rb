class CSVEventParser
  def parse(path, data)
    if (path.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1 || path.split(Manifest::PATH_SPLIT_TOKEN).size > 1
      raise "path nesting is unsupported for CSV Events"
    else
      data[path]
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

  def import_from path
    Dir.glob(File.join(path, "*.csv")).each do |file_name|
      File.open(file_name) do |file|
        # File name follows the pattern: "device_key-yyyymmddhhmmss.csv"
        load_for_device file, file_name.split("/").last[0..-("-yyyymmddhhmmss.csv".length + 1)]
      end
      File.delete(file_name)
    end
  end
end
