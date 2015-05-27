class Sample < ActiveRecord::Base
  include EventEncryption
  has_many :events
  belongs_to :institution
  belongs_to :patient
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

  def add_patient_data(patient)
    self.plain_sensitive_data[:patient] ||= {}
    self.plain_sensitive_data[:patient].deep_merge_not_nil!(patient.plain_sensitive_data)

    self.custom_fields[:patient] ||= {}
    self.custom_fields[:patient].deep_merge_not_nil!(patient.custom_fields)

    self.indexed_fields[:patient] ||= {}
    self.indexed_fields[:patient].deep_merge_not_nil!(patient.indexed_fields)
  end

  def extract_patient_data_into(patient)
    patient.plain_sensitive_data.reverse_deep_merge! (self.plain_sensitive_data[:patient] || {})
    patient.custom_fields.reverse_deep_merge! (self.custom_fields[:patient] || {})
    patient.indexed_fields.reverse_deep_merge! (self.indexed_fields[:patient] || {})

    self.plain_sensitive_data.delete(:patient)
    self.custom_fields.delete(:patient)
    self.indexed_fields.delete(:patient)
  end

  def plain_sensitive_data
    @plain_sensitive_data ||= (Oj.load(EventEncryption.decrypt(self.sensitive_data)) || {}).with_indifferent_access
  end

  def sample_uid
    self.plain_sensitive_data[:sample_uid]
  end

  def self.find_by_pii(sample_uid, institution_id)
    self.find_by(sample_uid_hash: EventEncryption.hash(sample_uid.to_s), institution_id: institution_id)
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
