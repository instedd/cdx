class AlertRecipient < ActiveRecord::Base

  belongs_to :user
  belongs_to :alert
  belongs_to :role

  enum recipient_type: [:role, :internal_user, :external_user]
end
