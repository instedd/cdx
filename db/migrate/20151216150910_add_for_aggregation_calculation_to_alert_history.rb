class AddForAggregationCalculationToAlertHistory < ActiveRecord::Migration
  def change
     add_column :alert_histories, :for_aggregation_calculation, :boolean, default:false
  end
end
