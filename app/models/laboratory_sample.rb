class LaboratorySample < ActiveRecord::Base
  include AutoUUID

  enum type: {
    specimen: "Specimen",
    qc: "QC"
  }

end
