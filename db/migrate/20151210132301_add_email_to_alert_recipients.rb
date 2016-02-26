class AddEmailToAlertRecipients < ActiveRecord::Migration
  def change
    add_column :alert_recipients, :email, :string
  end
end
