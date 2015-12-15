class AlertPage < SitePrism::Page
 set_url '/alerts/new'

  section 'form', '#new_alert' do
 #   element :category, '[name="alert[cateogry_type]"]'
      element :name, '#alert_name'
      element :description, '#alert_description'
     element :errors, '#alert_error_code'
   #   element :message, '#alert_MESSAGE'
  end
end



