class AddSmsLimitToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :sms_limit, :integer, default:0
  end
end
