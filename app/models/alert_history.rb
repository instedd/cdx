class AlertHistory < ActiveRecord::Base
  belongs_to :user
  belongs_to :alert
  belongs_to :test_result

  has_many  :recipient_notification_history
  
  def self.calculate_number_sms_sent_today(alert_id)
      AlertHistory.where("created_at >= ? and alert_id=? and for_aggregation_calculation =?",Time.zone.now.beginning_of_day, alert_id,false).count
  end
  
end
