class LaboratorySample < ActiveRecord::Base
  include Entity
  include AutoUUID

  belongs_to :institution
  validates_presence_of :institution

  belongs_to :batch
  validates_presence_of :batch

  has_one :test_qc_result
  has_many :notes
  accepts_nested_attributes_for :test_qc_result, allow_destroy: true
  accepts_nested_attributes_for :notes, allow_destroy: true

  def self.entity_scope
    "laboratory_sample"
  end

  attribute_field :is_quality_control

  def build_default_test_qc_result
    build_test_qc_result
  end
end
