class AddSmsMessageToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :sms_message, :text
  end
end
