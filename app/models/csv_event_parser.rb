class CSVEventParser
  def lookup(path, data)
    if (path.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1 || path.split(Manifest::PATH_SPLIT_TOKEN).size > 1
      raise "path nesting is unsupported for CSV Events"
    else
      data[path]
    end
  end

  def load_all(data)
    csv = CSV.new(data, col_sep: ';')
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
    CSV.generate_line(data.keys, col_sep: ';') + CSV.generate_line(data.values, col_sep: ';')
  end

  def load_for_device(data, device_key)
    device = Device.includes(:manifests, :institution, :laboratories, :locations).find_by!(secret_key: device_key)
    raw_events = load_all data
    events = raw_events.map do |raw_event|
      raw_event = dump raw_event
      Event.create_or_update_with device, raw_event
    end
    events.map do |event|
      {event: event[0].indexed_body, saved: event[1], errors: event[0].errors, index_failure_reason: event[0].index_failure_reason}
    end
  end

  def import_from(sync_dir)
    Rails.logger.info "Running import for #{sync_dir.sync_path}"
    sync_dir.each_inbox_file('*.csv', &load_file)
  end

  def import_single(sync_dir, filename)
    sync_dir.if_inbox_file(filename, '*.csv', &load_file)
  end

  private

  def load_file
    lambda do |secret_key, filename|
      Rails.logger.info "Importing #{filename} for device #{secret_key}"
      File.open(filename) { |file| load_for_device file, secret_key }
      File.delete(filename)
    end
  end
end
