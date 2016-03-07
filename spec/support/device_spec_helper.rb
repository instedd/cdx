class DeviceSpecHelper
  attr_reader :device_model

  def initialize(name)
    @device_model = DeviceModel.make name: name
    @sync_dir = CDXSync::SyncDirectory.new(Dir.mktmpdir('sync'))

    load_manifest @device_model, "#{name}_manifest.json"

    @sync_dir.ensure_sync_path!
  end

  def make(attributes = {})
    device = Device.make({device_model: device_model}.merge(attributes))

    @sync_dir.ensure_client_sync_paths! device.uuid

    device
  end

  def import_sample_csv(device, name)
    copy_sample_csv device, name
    DeviceMessageImporter.new("*.csv").import_from @sync_dir
  end

  def import_sample_json(device, name)
    copy_sample_json device, name
    DeviceMessageImporter.new("*.json").import_from @sync_dir
  end

  private

  def load_manifest(device_model, name)
    Manifest.create! device_model: device_model, definition: IO.read(File.join(Rails.root, 'db', 'seeds', 'manifests', name))
  end

  def copy_sample_csv(device, name)
    copy_sample(device, name, 'csvs')
  end

  def copy_sample_json(device, name)
    copy_sample(device, name, 'jsons')
  end

  def copy_sample(device, name, format)
    FileUtils.cp File.join(Rails.root, 'spec', 'fixtures', format, name), @sync_dir.inbox_path(device.uuid)
  end
end
