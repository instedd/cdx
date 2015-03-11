class Sample < ActiveRecord::Base
  include EventEncryption
  has_many :events
  belongs_to :institution
  before_save :encrypt
  before_create :generate_uuid
  before_create :ensure_sample_uid
  serialize :custom_fields
  serialize :indexed_fields
  validates_presence_of :institution
  validates_uniqueness_of :sample_uid_hash, scope: :institution_id, allow_nil: true

  attr_writer :plain_sensitive_data

  after_initialize do
    self.custom_fields  ||= {}
    self.indexed_fields ||= {}
  end

  def merge sample
    self.plain_sensitive_data.deep_merge_not_nil!(sample.plain_sensitive_data)
    self.custom_fields.deep_merge_not_nil!(sample.custom_fields)
    self.indexed_fields.deep_merge_not_nil!(sample.indexed_fields)

    self
  end

  def plain_sensitive_data
    @plain_sensitive_data ||= (Oj.load(EventEncryption.decrypt(self.sensitive_data)) || {}).with_indifferent_access
  end

  def encrypt
    self.sensitive_data = EventEncryption.encrypt Oj.dump(self.plain_sensitive_data)
    self
  end

  def generate_uuid
    self.uuid ||= Guid.new.to_s
  end

  def ensure_sample_uid
    self.sample_uid_hash ||= EventEncryption.hash(self.plain_sensitive_data[:sample_uid].to_s) if self.plain_sensitive_data[:sample_uid]
  end
end
