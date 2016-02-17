class AddRolesToAlertRecipients < ActiveRecord::Migration
  def change
    change_table :alert_recipients do |t|
      t.references :role
    end
  end
end



