class AddTimeLastAggregationCheckedToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :time_last_aggregation_checked, :datetime
  end
end
