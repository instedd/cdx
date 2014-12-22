class SshKey < ActiveRecord::Base

  belongs_to :device

  validates_presence_of :public_key

  class << self
    def regenerate_authorized_keys!
      authorized_keys.write! clients, sync_dir
    end

    def clients
      all.map { |key| CDXSync::Client.new("device-#{key.device_id}", key.public_key) }
    end

    private

    def authorized_keys
      CDXSync::AuthorizedKeys.new
    end

    def sync_dir
      CDXSync::SyncDirectory.new
    end
  end

end
