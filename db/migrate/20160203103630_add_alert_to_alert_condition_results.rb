class AddAlertToAlertConditionResults < ActiveRecord::Migration
  def change
    add_column :alert_condition_results, :alert_id, :integer
  end
end
