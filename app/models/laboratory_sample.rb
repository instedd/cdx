class LaboratorySample < ActiveRecord::Base
  include Entity
  include AutoUUID

  belongs_to :institution
  validates_presence_of :institution

  belongs_to :batch
  validates_presence_of :batch

  has_one :qc_result, class_name: "TestQcResult"

  def self.entity_scope
    "laboratory_sample"
  end

  attribute_field :is_quality_control
end
