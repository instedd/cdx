class Patient < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoUiHash

  belongs_to :institution
  has_many :test_results
  has_many :samples

  validates_presence_of :institution

  def entity_uid
    plain_sensitive_data["id"]
  end

  def entity_scope
    "patient"
  end
end
