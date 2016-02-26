class AddRecipientTypeToAlertRecipients < ActiveRecord::Migration
  def change
    add_column :alert_recipients, :recipient_type, :integer, default:0
    add_column :alert_recipients, :telephone, :string
    add_column :alert_recipients, :first_name, :string
    add_column :alert_recipients, :last_name, :string
  end
end
