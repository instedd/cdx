class CreateJoinTableAlertDevice < ActiveRecord::Migration
  def change
    create_join_table :alerts, :devices do |t|
       t.index [:alert_id, :device_id]
       t.index [:device_id, :alert_id]
    end
  end
end

