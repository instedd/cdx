# Imports plain files from sync dirs
class DeviceEventImporter

  attr_reader :pattern

  def initialize(pattern="*.csv")
    @pattern = pattern
  end

  def import_from(sync_dir)
    Rails.logger.info "Running import for #{sync_dir.sync_path} with pattern #{pattern}"
    sync_dir.each_inbox_file(@pattern, &load_file)
  end

  def import_single(sync_dir, filename)
    sync_dir.if_inbox_file(filename, @pattern, &load_file)
  end

  def load_for_device(data, device_uuid)
    device = Device.includes(:manifests, :institution, :laboratories, :locations).find_by!(uuid: device_uuid)
    device_event = DeviceEvent.new(device: device, plain_text_data: data)
    device_event.process if device_event.save && !device_event.index_failed?
  end

  private

  def load_file
    lambda do |uuid, filename|
      Rails.logger.info "Importing #{filename} for device #{uuid}"
      File.open(filename) { |file| load_for_device file.read, uuid }
      File.delete(filename)
    end
  end

end
