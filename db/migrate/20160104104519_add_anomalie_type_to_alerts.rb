class AddAnomalieTypeToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :anomalie_type, :integer, default:0
  end
end
