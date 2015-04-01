class DeviceModel < ActiveRecord::Base
  has_and_belongs_to_many :manifests
  has_many :devices
  scope :active, -> { joins(:manifests).distinct }

  def current_manifest
    manifests.order("id").last
  end
end
