require 'net/ftp'
require 'tempfile'
require 'zip'
Zip.on_exists_proc = true

class FtpMonitor
  def initialize(sleep_interval_in_seconds=300)
    @sleep_interval = sleep_interval_in_seconds
  end

  def run!
    while true
      self.process!
      sleep @sleep_interval
    end
  end

  def process!
    device_groups.each do |ftp, devices|
    next if ftp.hostname.blank?
    # TODO: Should we move these actions to a background task?
      FtpProcessor.new(ftp, devices).process!
    end
  end

  def device_groups
    Device.joins(:device_model).where(device_models: { supports_ftp: true }).group_by(&:ftp_info)
  end

  class FtpProcessor
    attr_reader :ftp_info, :devices, :ftp

    def initialize(ftp_info, devices)
      @ftp_info = ftp_info
      @devices = devices
    end

    def process!
      # Connect and list files
      open_ftp!
      files = ftp.nlst
      Rails.logger.info("Listed files from #{ftp_info.hostname}: #{files.join(', ')}")
      # Remove files already seen
      files -= already_reviewed_files

      # Download all files
      downloaded = download_files(files)
      unless downloaded.present?
        Rails.logger.info("Error downloading files from #{ftp_info.hostname}: #{files.join(', ')}")
        return nil
      end

      Rails.logger.info("Downloaded files from #{ftp_info.hostname}: #{downloaded.join(', ')}")

      # Done with remote server
      ftp.quit rescue nil

      # Process them and close temp files
      downloaded.compact.each do |remote_name, tempfile|
        if /.*\.zip/.match(remote_name)
          process_zip_file tempfile
        else
          process_file remote_name, tempfile
        end
      end

      nil
    rescue => ex
      log_error(ex)
    end

    def process_zip_file(tempfile)
      Zip::File.open(tempfile) do |zip_file|
        zip_file.each do |file|
          next if file.name.match(/__MACOSX/)
          tempfile = Tempfile.new(File.basename(file.name), Rails.root.join('tmp'))
          file.extract(tempfile.path)
          process_file file.name, tempfile
        end
      end
    end

    def already_reviewed_files
      FileMessage.where(
        ftp_hostname: ftp_info.hostname,
        ftp_port: ftp_info.port,
        ftp_directory: ftp_info.directory,
        status: %w(failed success)
      ).pluck(:filename)
    end

    def open_ftp!
      @ftp = Net::FTP.new
      @ftp.connect ftp_info.hostname, ftp_info.port
      @ftp.login ftp_info.username, ftp_info.password if ftp_info.username
      @ftp.passive = ftp_info.passive.present?
      @ftp.chdir ftp_info.directory if ftp_info.directory
      @ftp
    end

    def process_file(remote_name, file)
      file.rewind
      device = match_device(remote_name)
      return if device.nil?
      create_and_process_device_message_for(remote_name, device, file)
    ensure
      file.close
      file.unlink rescue nil
    end

    def create_and_process_device_message_for(remote_name, device, file)
      device_message = DeviceMessage.new(device: device, plain_text_data: file.read)

      if device_message.save && !device_message.index_failed? && device_message.process && !device_message.index_failed?
        successful_file(remote_name, device_message)
      else
        failed_file(remote_name, device_message.error_description, nil, device_message)
      end
    rescue => ex
      failed_file(remote_name, 'Unexpected error processing file', ex, device_message)
    end

    def match_device(remote_name)
      # Extract device message info
      matches = patterns.map { |p, ds| [File.basename(remote_name).match(p), ds] }
      devices = matches.flat_map { |m, ds| m ? ds.select { |d| d.serial_number == m[:sn] } : [] }

      # Skip file if no device or multiple devices have matched its name
      return skip_file(remote_name, 'No device matched') if devices.empty?
      return skip_file(remote_name, "Multiple devices have matched file #{remote_name}: #{devices.map(&:serial_number)}") if devices.length > 1
      devices.first
    rescue => ex
      failed_file(remote_name, 'Unexpected error matching file', ex)
    end

    def download_files(files)
      files.map do |filename|
        begin
          tempfile = Tempfile.new(File.basename(filename), Rails.root.join('tmp'))
          ftp.getbinaryfile filename, tempfile.path
          [filename, tempfile]
        rescue => ex
          failed_file(filename, "Error downloading file", ex)
          break
        end
      end
    end

    def skip_file(remote_name, reason)
      # TODO: Decide whether we want to log this info in DB as well for all affected devices
      # devices.each { |device| FileMessage.create(filename: remote_name, ftp_info: ftp_info, status: 'skipped', message: reason, device: device) }
      Rails.logger.info("Skipping FTP file #{remote_name} on hostname #{ftp_info[:hostname]}: #{reason}")
      nil
    end

    def failed_file(remote_name, reason, exception=nil, device_message=nil)
      FileMessage.create(filename: remote_name, ftp_info: ftp_info, status: 'failed', message: reason, device: device_message.try(:device), device_message_id: device_message.try(:id))
      msg = "FTP file #{remote_name} on hostname #{ftp_info[:hostname]} failed: #{reason}"
      msg += "\n#{exception}" if exception
      msg += "\n#{exception.backtrace.join("\n")}" if exception && exception.respond_to?(:backtrace)
      Rails.logger.warn(msg)
      nil
    end

    def successful_file(remote_name, device_message)
      FileMessage.create(filename: remote_name, ftp_info: ftp_info, status: 'success', message: nil, device: device_message.device, device_message_id: device_message.id)
      Rails.logger.info("FTP file #{remote_name} on hostname #{ftp_info[:hostname]} processed successfuly")
      nil
    end

    def log_error(ex)
      devices.each { |device| FileMessage.create(ftp_info: ftp_info, device: device, message: "Error accessing FTP: #{ex}", status: 'error') }
      Rails.logger.warn("Error accessing FTP #{ftp_info.hostname}: #{ex}\n#{ex.backtrace.join("\n")}")
      ex
    end

    def patterns
      @patterns ||= devices.group_by { |d| d.device_model.filename_pattern }
    end
  end
end
