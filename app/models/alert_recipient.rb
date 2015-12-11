class AlertRecipient < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :alert
  
#  validates_presence_of :user_id, :alert_id
end
 
