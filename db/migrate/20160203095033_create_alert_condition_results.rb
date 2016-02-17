class CreateAlertConditionResults < ActiveRecord::Migration
  def change
    create_table :alert_condition_results do |t|
      t.string :result
    end
  end
end
