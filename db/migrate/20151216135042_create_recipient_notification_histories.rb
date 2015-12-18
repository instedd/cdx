class CreateRecipientNotificationHistories < ActiveRecord::Migration
  def change
    create_table :recipient_notification_histories do |t|
      t.references :user, index: true
      t.references :alert_recipient
      t.references :alert_history
      t.references :alert
      t.integer :channel_type
      t.string :message_sent
      t.timestamps
    end
  end
end
