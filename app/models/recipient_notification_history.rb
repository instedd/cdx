class RecipientNotificationHistory < ActiveRecord::Base
  belongs_to :user
  belongs_to :alert
  belongs_to :alert_history
  belongs_to :alert_recipient
end
