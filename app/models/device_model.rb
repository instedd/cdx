class DeviceModel < ActiveRecord::Base
  has_and_belongs_to_many :manifests

  def current_manifest
    @manifest ||= manifests.order("version DESC").first
  end

  def reload!
    super
    @manifest = nil
  end
end
