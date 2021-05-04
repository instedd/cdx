class LaboratorySample < ActiveRecord::Base
  include AutoUUID

  enum sample_type: { Specimen: 'specimen', QC: 'qc' }

end
