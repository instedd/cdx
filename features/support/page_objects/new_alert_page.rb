class NewAlertPage < SitePrism::Page
  set_url '/alerts/new'

  section 'form', '#new_alert' do
    element :name, '#alertname'
    element :description, '#alertdescription'
    element :errorcode_category, '#device_errors'

    section :anomalies, CdxSelect, "label", text: /Anomalie Type/i
    element :device_errors_value, "#alerterrorcode"

    element :emaillimit, '#alertemaillimit'
    element :message, '#alertmessage'
    element :smsmessage, '#alertsmsmessage'
    element :smslimit, '#alertsmslimit'

    section :aggregation, CdxSelect, "label", text: /Aggregation Type/i
    section :aggregation_frequency, CdxSelect, "label", text: /Aggregation Frequency/i
    element :aggregationthresholdlimit, '#alertaggregationthresholdlimit'
    element :aggregationthresholdpercentage, '#alertaggregationpercentage'
    
    element :timespan, '#alertutilizationefficiencynumber'
    section :channel, CdxSelect, "label", text: /Channel/i

    section :sites, CdxSelect, "label", text: /Sites/i
    section :devices, CdxSelect, "label", text: /Devices/i
    section :roles, CdxSelect, "label", text: /Roles/i
    
    element :sampleid, '#alertsampleid'
    
    section :conditions, CdxSelect, "label", text: /Conditions/i
    section :condition_results, CdxSelect, "label", text: /Condition Results/i
    
    section :internal_users, CdxSelect, "label", text: /Internal Recipient/i
    element :externaluser_firstname, '#externaluser_firstname'
    element :externaluser_lastname, '#externaluser_lastname'
    element :externaluser_email, '#externaluser_email'
    element :externaluser_telephone, '#externaluser_telephone'
    element :new_externaluser, '#newexternaluser'

    element :submit, '#submit'
    
    element :delete, '#delete_alert'
  end
end
