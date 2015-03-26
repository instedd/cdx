class DeviceModel < ActiveRecord::Base
  has_and_belongs_to_many :manifests
  scope :active, -> { joins(:manifests).distinct }

  def current_manifest
    manifests.order("id").last
  end
end
