class Sample < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoIdHash

  belongs_to :institution
  belongs_to :patient
  belongs_to :encounter

  has_many :test_results

  validates_presence_of :institution

  def entity_id
    core_fields["id"]
  end

  def self.entity_scope
    "sample"
  end
end
