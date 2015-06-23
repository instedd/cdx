class DeviceModel < ActiveRecord::Base
  has_and_belongs_to_many :manifests
  has_many :devices

  scope :active, -> { joins(:manifests).distinct }

  def current_manifest
    @manifest ||= manifests.order("id").last || (raise ManifestParsingError.no_manifest(self))
  end

  def reload
    super
    @manifest = nil
  end
end
