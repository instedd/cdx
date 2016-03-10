class AddSmsToRecipientNotificationHistories < ActiveRecord::Migration
  def change
    add_column :recipient_notification_histories, :sms_response_id, :integer
    add_column :recipient_notification_histories, :sms_response_guid, :string
    add_column :recipient_notification_histories, :sms_response_token, :string
  end
end



