class Sample < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoUiHash

  belongs_to :institution
  belongs_to :patient
  belongs_to :encounter

  has_many :test_results

  validates_presence_of :institution

  def entity_uid
    core_fields["id"]
  end

  def entity_scope
    "sample"
  end
end
