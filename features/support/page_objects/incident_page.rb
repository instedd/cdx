class IncidentsPage < CdxPageBase
  set_url "/incidents"

  section 'form', '#filters-form'    do
    section :alert_group, CdxSelect, "label", text: /Alert Group/i
    section :select_date, CdxSelect, "label", text: /Date/i
  end
    
  section :table, CdxTable, "table"
end
