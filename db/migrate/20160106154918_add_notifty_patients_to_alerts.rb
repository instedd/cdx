class AddNotiftyPatientsToAlerts < ActiveRecord::Migration
  def change
      add_column :alerts, :notify_patients, :boolean, default:0
  end
end