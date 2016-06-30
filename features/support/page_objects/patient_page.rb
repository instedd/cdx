class PatientPage < CdxPageBase
  set_url '/patients{/patient_id}{?query*}'
end

class PatientEditPage < CdxPageBase
  set_url '/patients/{id}/edit{?query*}'

  element :delete, :link, 'Delete'
  element :name, :field, "Name"
end

class PatientsPage < CdxPageBase
  set_url '/patients/{?query*}'

  section :table, CdxTable, "table"
end

def filters
  "form#filters-form"
end