class LaboratorySample < ApplicationRecord
  include AutoUUID

  enum sample_type: { Specimen: 'specimen', QC: 'qc' }

end
