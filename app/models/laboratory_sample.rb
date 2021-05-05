class LaboratorySample < ActiveRecord::Base
  include AutoUUID

  enum sample_type: { Specimen: 'specimen', QC: 'qc' }

  validates_presence_of :sample_type
end
