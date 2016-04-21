class CreateAlertRecipients < ActiveRecord::Migration
  def change
    create_table :alert_recipients do |t|
      t.references :user, index: true
      t.references :alert, index: true
      t.timestamps
    end
  end
end
