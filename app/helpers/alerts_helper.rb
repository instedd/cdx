module AlertsHelper
  def display_sites(alert)
    site_names = alert.sites.inject {|site,n| site.name + ','+n.name}
    if site_names == nil
      ""
    else
      site_names
    end  
  end

  def display_roles(alert)
    role_names=[]
    alert.alert_recipients.each do |recipient|
      if AlertRecipient.recipient_types[recipient.recipient_type] == AlertRecipient.recipient_types["role"]
        role = Role.find(recipient.role_id)
        role_names<< role.name
      end
    end
    role_names.join(',')
  end
  
  def display_devices(alert)
    device_names=[]
    alert.devices.each do |device|
        device_names<< device.name
    end
    device_names.join(',')
  end
  

  def display_latest_alert_date(alert)
    alertHistory=AlertHistory.where("alert_id=?",alert.id).order(:created_at).last
    if alertHistory==nil
      'never'
    else
      alertHistory.created_at.to_formatted_s(:long)
    end
  end

end
