# Imports plain files from sync dirs
class DeviceEventImporter

  attr_reader :pattern

  def initialize(pattern="*.csv")
    @pattern = pattern
  end

  def import_from(sync_dir)
    Rails.logger.info "Running import for #{sync_dir.sync_path} with pattern #{pattern}"
    sync_dir.each_inbox_file(@pattern, &load_file(sync_dir))
  end

  def import_single(sync_dir, filename)
    sync_dir.if_inbox_file(filename, @pattern, &load_file(sync_dir))
  end

  def load_for_device(data, device_uuid)
    device = Device.includes(:manifests, :institution, :laboratories).find_by!(uuid: device_uuid)
    device_event = DeviceEvent.new(device: device, plain_text_data: data)
    device_event.save!
    Rails.logger.debug("Saved device event #{device_event.id} for device #{device_uuid}")

    if device_event.index_failed?
      Rails.logger.warn "Parsing failed for device event #{device_event.id}"
    else
      begin
        device_event.process
      rescue => ex
        Rails.logger.error("Error processing device event #{device_event.id}: #{ex}\n #{ex.backtrace.join("\n")}")
      else
        Rails.logger.debug("Processed device event #{device_event.id}")
      end
    end
  end

  private

  def load_file(sync_dir)
    lambda do |uuid, filename|
      PoirotRails::Activity.current.merge! device_uuid: uuid
      Rails.logger.info "Importing #{filename} for device #{uuid}"
      begin
        encoding = CharDet.detect(File.read(filename))
        File.open(filename, internal_encoding: 'UTF-8', external_encoding: "#{encoding['encoding']}") do |file|
          load_for_device file.read, uuid
        end
        File.delete(filename)
      rescue => ex
        Rails.logger.error "Error processing #{filename} with encoding #{encoding || 'nil'} for device #{uuid}: #{ex}\n #{ex.backtrace.join("\n ")}"
        sync_dir.move_inbox_file_to_error(filename)
      end
    end
  end

end
