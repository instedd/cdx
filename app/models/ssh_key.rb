class SshKey < ActiveRecord::Base  
  belongs_to :device

  validates_presence_of :public_key

  def self.regenerate_authorized_keys!
    CDXSync::SshKey.regenerate_authorized_keys(all_public_keys)
  end

  def self.all_public_keys
    all.pluck(:public_key)
  end
end
