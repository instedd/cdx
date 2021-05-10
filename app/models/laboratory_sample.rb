class LaboratorySample < ActiveRecord::Base
  include AutoUUID

  belongs_to :institution
  validates_presence_of :institution

  enum sample_type: { Specimen: 'specimen', QC: 'qc' }

  validates_presence_of :sample_type
end
