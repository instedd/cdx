class AddUseAggregationPercentageToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :use_aggregation_percentage, :boolean, default:0
  end
end
