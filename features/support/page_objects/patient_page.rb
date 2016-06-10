class PatientPage < CdxPageBase
  set_url '/patients{/patient_id}{?query*}'
end

class PatientsPage < CdxPageBase
  set_url '/patients'
end

def filters
  "form#filters-form"
end