class DeviceModel < ActiveRecord::Base
  has_one :manifest, dependent: :destroy, inverse_of: :device_model
  validates_uniqueness_of :name
  has_many :devices

  accepts_nested_attributes_for :manifest

  #This is kept for forward compatibility (we will have multiple manifests, published and unpublished)
  alias_method :current_manifest, :manifest
end
