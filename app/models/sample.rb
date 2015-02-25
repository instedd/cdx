class Sample < ActiveRecord::Base
  include EventEncryption
  has_many :events
  belongs_to :institution
  before_save :encrypt
  before_create :generate_uuid
  before_create :ensure_sample_id

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

  def ensure_sample_id
    self.sample_id ||= self.uuid
  end
end
