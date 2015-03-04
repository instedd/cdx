class Sample < ActiveRecord::Base
  include EventEncryption
  has_many :events
  belongs_to :institution
  before_save :encrypt
  before_create :generate_uuid
  before_create :ensure_sample_uid

  attr_writer :plain_sensitive_data

  def merge_sensitive_data pii
    self.plain_sensitive_data.merge!(pii.delete_if {|k,v| v.nil?})
  end

  def plain_sensitive_data
    @plain_sensitive_data ||= (Oj.load(EventEncryption.decrypt(self.sensitive_data)) || {}).with_indifferent_access
  end

  def encrypt
    self.sensitive_data = EventEncryption.encrypt Oj.dump(self.plain_sensitive_data)
    self
  end

  def generate_uuid
    self.uuid = Guid.new.to_s
  end

  def ensure_sample_uid
    self.sample_uid_hash ||= EventEncryption.hash(self.plain_sensitive_data[:sample_uid]) if self.plain_sensitive_data[:sample_uid]
  end
end
