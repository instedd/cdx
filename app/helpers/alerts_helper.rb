module AlertsHelper
  include ActionView::Helpers::DateHelper

  def display_sites(alert)
    site_names = alert.sites.map(&:name).join ', '
    if site_names.nil?
      ''
    else
      site_names
    end
  end

  def display_roles(alert)
    role_names = []
    alert.alert_recipients.each do |recipient|
      if AlertRecipient.recipient_types[recipient.recipient_type] == AlertRecipient.recipient_types['role']
        role = Role.find(recipient.role_id)
        role_names << role.name
      end
    end
    role_names.join(',')
  end

  def display_devices(alert)
    device_names = []
    alert.devices.each do |device|
      device_names << device.name
    end
    device_names.join(',')
  end

  def display_latest_alert_date(alert)
    alert_history = AlertHistory.where('alert_id=?', alert.id).order(:created_at).last
    if alert_history.nil?
      'never'
    else
      time_ago_in_words(alert_history.created_at) + ' ago'
    end
  end
end
