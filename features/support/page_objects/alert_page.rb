class AlertPage < SitePrism::Page
 set_url '/alerts/new'

  section 'form', '#new_alert' do
 #   element :category, '[name="alert[cateogry_type]"]'
      element :name, '#alertname'
      element :description, '#alertdescription'
      element :errorcode_category, '#device_errors'
  #     element :errors, '#alerterrorcode'
     element :message, '#alertmessage'
   #   element :message, '#alert_MESSAGE'
    element :submit, '#submit'
  end
end



