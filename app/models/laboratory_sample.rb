class LaboratorySample < ActiveRecord::Base
  include Entity
  include AutoUUID

  belongs_to :institution
  validates_presence_of :institution

  def self.entity_scope
    "laboratory_sample"
  end

  attribute_field :sample_type, copy: true

  SAMPLE_TYPE_VALUES = LaboratorySample.entity_fields.detect { |f| f.name == 'sample_type' }.options
  validates_presence_of :sample_type
  validates_inclusion_of :sample_type, in: SAMPLE_TYPE_VALUES, message: "is not within valid options (should be one of #{SAMPLE_TYPE_VALUES.join(', ')})"
end
