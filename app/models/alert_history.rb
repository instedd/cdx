class AlertHistory < ActiveRecord::Base
  belongs_to :user
  belongs_to :alert
  belongs_to :test_result

  has_many  :recipient_notification_history
end
