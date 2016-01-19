module AlertsHelper
  def display_sites(alert)
    alert.sites.inject {|site,n| site.name + ','+n.name}
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

  def display_latest_alert_date(alert)
    latest_date='-'
    alertHistory=AlertHistory.where("alert_id=?",alert.id).order(:created_at).last
    latest_date = alertHistory.created_at.to_formatted_s(:long) if alertHistory!=nil
  end

end
