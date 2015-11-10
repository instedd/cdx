class Patient < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoIdHash

  belongs_to :institution

  has_many :test_results, dependent: :restrict_with_error
  has_many :samples, dependent: :restrict_with_error
  has_many :encounters, dependent: :restrict_with_error

  validates_presence_of :institution

  def entity_id
    plain_sensitive_data["id"]
  end

  def has_entity_id?
    entity_id_hash.not_nil?
  end

  def self.entity_scope
    "patient"
  end
end
