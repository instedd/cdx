class AlertPage < SitePrism::Page
 set_url '/alerts/new'
 #  set_url '/policies/new'

  section 'form', '#new_alert' do
 #   element :category, '[name="alert[cateogry_type]"]'
 #     element :name, '#alert_name'
   #   element :errors, '#alert_ERRORS'
   #   element :message, '#alert_MESSAGE'
  end
end
