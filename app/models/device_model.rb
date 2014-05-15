class DeviceModel < ActiveRecord::Base
  has_and_belongs_to_many :manifests
end
