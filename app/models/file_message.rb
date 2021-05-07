# Represents a file in a remote location containing a device message to be processed
class FileMessage < ApplicationRecord
  validates :status, inclusion: { in: %w(success failed skipped error) }

  belongs_to :device
  belongs_to :device_message

  composed_of :ftp_info, mapping: FtpInfo.mapping('ftp_')
end
