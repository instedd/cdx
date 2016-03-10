class AddAggregationFrequencyToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :aggregation_frequency, :integer, default:0
  end
end
