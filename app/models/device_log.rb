class DeviceLog < ApplicationRecord
  belongs_to :device

  serialize :message, ZipSerialize
end