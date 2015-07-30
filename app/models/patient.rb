class Patient < ActiveRecord::Base
  include AutoUUID
  include Entity

  belongs_to :institution
  has_many :test_results, dependent: :restrict_with_error
  has_many :samples, dependent: :restrict_with_error

  validates_presence_of :institution
  validates_uniqueness_of :patient_id_hash, scope: :institution_id, allow_nil: true

  before_create :ensure_patient_id_hash

  def patient_id
    self.plain_sensitive_data["patient"]["id"]
  end

  def self.find_by_pii(patient_id, institution_id)
    self.find_by(patient_id_hash: MessageEncryption.hash(patient_id.to_s), institution_id: institution_id)
  end

private

  def ensure_patient_id_hash
    self.patient_id_hash ||= MessageEncryption.hash(patient_id.to_s) if patient_id
  end
end
