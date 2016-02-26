class IncidentsPage < CdxPageBase
  set_url "/incidents"

  section 'form', '#filters-form'    do
    section :alertgroup, CdxSelect, "label", text: /Alert Group/i
    section :selectdate, CdxSelect, "label", text: /Date/i
  end
    
  section :table, CdxTable, "table"
end
