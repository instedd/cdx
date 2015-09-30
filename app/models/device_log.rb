class DeviceLog < ActiveRecord::Base
  belongs_to :device

  serialize :message, ZipSerialize
end