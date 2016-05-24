class PatientPage < CdxPageBase
  set_url '/patients{/patient_id}{?query*}'
end

def patient_filter
  "form#filters-form"
end