class Sample < ActiveRecord::Base
  include EventEncryption
  has_many :events
  before_save :encrypt
  before_create :generate_uuid

  def merge_sensitive_data pii
    decrypt if sensitive_data.is_a? String
    self.sensitive_data ||= {}
    self.sensitive_data.merge!(pii.delete_if {|k,v| v.nil?})
  end

  def decrypt
    self.sensitive_data = Oj.load(EventEncryption.decrypt self.sensitive_data).try(:with_indifferent_access)
    self
  end

  def encrypt
    self.sensitive_data = EventEncryption.encrypt Oj.dump(self.sensitive_data)
    self
  end

  def generate_uuid
    self.uuid = Guid.new.to_s
  end
end
