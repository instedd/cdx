class PatientPage < CdxPageBase
  set_url '/patients{/patient_id}{?query*}'
end

def filters
  "form#filters-form"
end