class Encounter < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoUiHash

  has_many :test_results

  belongs_to :institution
  belongs_to :patient

  validates_presence_of :institution

  def entity_uid
    plain_sensitive_data["id"]
  end

  def entity_scope
    "encounter"
  end
end
