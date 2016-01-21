class AlertRecipient < ActiveRecord::Base
  belongs_to :user
  belongs_to :alert
  belongs_to :role

  enum recipient_type: [:role, :internal_user, :external_user]
  
  validates_presence_of :first_name, length: { minimum: 2 } 
  validates_presence_of :last_name, length: { minimum: 2 } 
  
end
