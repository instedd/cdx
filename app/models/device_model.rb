class DeviceModel < ActiveRecord::Base
  has_and_belongs_to_many :manifests

  def current_manifest
    manifests.order("id").last
  end
end
