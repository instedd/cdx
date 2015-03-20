class SshKey < ActiveRecord::Base
  belongs_to :device

  validates_uniqueness_of :device_id
  validates_presence_of :public_key, :device
  validate :validate_public_key

  def validate_public_key
    to_client.validate! unless public_key.blank?
  rescue
    errors.add(:public_key, "Key #{public_key.truncate(10)} is invalid")
  end

  def to_client
    SyncHelpers.to_client(device, public_key)
  end

  def self.regenerate_authorized_keys!
    SyncHelpers.regenerate_authorized_keys!(clients)
  end

  def self.clients
    all.map(&:to_client)
  end
end
