class LaboratorySample < ActiveRecord::Base
  include Entity
  include AutoUUID

  belongs_to :institution
  validates_presence_of :institution

  belongs_to :batch
  validates_presence_of :batch

  def self.entity_scope
    "laboratory_sample"
  end

  attribute_field :is_quality_control

  validates_presence_of :is_quality_control
end
