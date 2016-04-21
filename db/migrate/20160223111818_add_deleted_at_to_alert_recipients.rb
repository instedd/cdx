class AddDeletedAtToAlertRecipients < ActiveRecord::Migration
  def change
    add_column :alert_recipients, :deleted_at, :datetime
    add_index :alert_recipients, :deleted_at
  end
end
