class AddEmailLimitToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :email_limit, :integer, default:0
  end
end
