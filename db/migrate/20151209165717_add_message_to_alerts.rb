class AddMessageToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :message, :text
  end
end
