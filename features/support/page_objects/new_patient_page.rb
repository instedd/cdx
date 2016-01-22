class NewPatientPage < CdxPageBase
  set_url "/patients/new{?query*}"

  element :name, :field, "Name"
  element :patient_id, :field, "Patient id"

end
