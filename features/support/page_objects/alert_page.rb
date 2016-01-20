class AlertPage < SitePrism::Page
  set_url '/alerts/new'

  section 'form', '#new_alert' do
    element :name, '#alertname'
    element :description, '#alertdescription'
    element :errorcode_category, '#device_errors'

    section :anomalies, CdxSelect, "label", text: /Anomalie Type/i
    element :device_errors_value, "#alerterrorcode"
    
    element :message, '#alertmessage'
    element :smsmessage, '#alertsmsmessage'
    element :smslimit, '#alertsmslimit'

    section :aggregation, CdxSelect, "label", text: /Aggregation Type/i
    section :aggregation_frequency, CdxSelect, "label", text: /Aggregation Frequency/i
    section :channel, CdxSelect, "label", text: /Channel/i

    element :submit, '#submit'
  end
end
