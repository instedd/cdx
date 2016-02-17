class AddThresholdToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :test_result_min_threshold, :integer
    add_column :alerts, :test_result_max_threshold, :integer
  end
end
