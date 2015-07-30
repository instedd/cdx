class Encounter < ActiveRecord::Base
  include AutoUUID
  include Entity

  has_many :test_results, dependent: :restrict_with_error

  belongs_to :institution
  belongs_to :patient

  validates_presence_of :institution

  before_create :ensure_encounter_id_hash

  def encounter_id
    (plain_sensitive_data["encounter"] || {})["id"]
  end

  def self.find_by_pii(encounter_id, institution_id)
    self.find_by(encounter_id_hash: MessageEncryption.hash(encounter_id.to_s), institution_id: institution_id)
  end

private

  def ensure_encounter_id_hash
    self.encounter_id_hash ||= MessageEncryption.hash(encounter_id.to_s) if encounter_id
  end
end
