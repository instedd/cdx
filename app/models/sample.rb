class Sample < ActiveRecord::Base
  include AutoUUID
  include Entity

  belongs_to :institution
  belongs_to :patient
  belongs_to :encounter

  has_many :test_results, dependent: :restrict_with_error

  validates_presence_of :institution
  validates_uniqueness_of :sample_uid_hash, scope: :institution_id, allow_nil: true

  before_create :ensure_sample_uid_hash

  def sample_uid
    self.plain_sensitive_data["sample"]["uid"]
  end

  def self.find_by_pii(sample_uid, institution_id)
    self.find_by(sample_uid_hash: MessageEncryption.hash(sample_uid.to_s), institution_id: institution_id)
  end

private

  def ensure_sample_uid_hash
    self[:sample_uid_hash] ||= MessageEncryption.hash(sample_uid.to_s) if sample_uid
  end
end
