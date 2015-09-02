class Patient < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoIdHash

  belongs_to :institution
  has_many :test_results
  has_many :samples

  validates_presence_of :institution

  def entity_id
    plain_sensitive_data["id"]
  end

  def self.entity_scope
    "patient"
  end
end
