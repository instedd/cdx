class CreateJoinTableAlertCondition < ActiveRecord::Migration
  def change
    create_join_table :alerts, :conditions do |t|
       t.index [:alert_id, :condition_id]
       t.index [:condition_id, :alert_id]
    end
  end
end
