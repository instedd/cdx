class AlertRecipient < ActiveRecord::Base
  
#friday  belongs_to :user
  belongs_to :alert
  belongs_to :role
  
#  has_many  :recipient_notification_history
  
#  validates_presence_of :user_id, :alert_id
end
 
