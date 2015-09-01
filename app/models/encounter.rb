class Encounter < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoIdHash

  has_many :test_results

  belongs_to :institution
  belongs_to :patient

  validates_presence_of :institution

  def entity_id
    core_fields["id"]
  end

  def entity_scope
    "encounter"
  end
end
