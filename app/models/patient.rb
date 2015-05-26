class Patient < ActiveRecord::Base
  has_many :samples
  belongs_to :institution

  before_save :encrypt
  before_create :generate_uuid
  before_create :ensure_patient_id_hash

  serialize :custom_fields
  serialize :indexed_fields

  validates_presence_of :institution
  validates_uniqueness_of :patient_id_hash, scope: :institution_id, allow_nil: true

  attr_writer :plain_sensitive_data

  after_initialize do
    self.custom_fields  ||= {}
    self.indexed_fields ||= {}
  end

  def plain_sensitive_data
    @plain_sensitive_data ||= (Oj.load(EventEncryption.decrypt(self.sensitive_data)) || {}).with_indifferent_access
  end

  def self.find_by_pii(patient_id)
    self.find_by_patient_id_hash EventEncryption.hash(patient_id.to_s)
  end

private

  def generate_uuid
    self.uuid ||= Guid.new.to_s
  end

  def encrypt
    self.sensitive_data = EventEncryption.encrypt Oj.dump(self.plain_sensitive_data)
    self
  end

  def ensure_patient_id_hash
    self.patient_id_hash ||= EventEncryption.hash(self.plain_sensitive_data[:patient_id].to_s) if self.plain_sensitive_data[:patient_id]
  end
end
