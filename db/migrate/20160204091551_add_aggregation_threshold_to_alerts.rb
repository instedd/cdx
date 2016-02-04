class AddAggregationThresholdToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :aggregation_threshold, :integer, default:0
  end
end
