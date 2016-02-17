class AddUtilizationEfficiencyToAlerts < ActiveRecord::Migration
  def change
     add_column :alerts, :utilization_efficiency_type, :integer, default:0
     add_column :alerts, :utilization_efficiency_number, :integer, default:0
     add_column :alerts, :utilization_efficiency_last_checked, :datetime
  end
end
