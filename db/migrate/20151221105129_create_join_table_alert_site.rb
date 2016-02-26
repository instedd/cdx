class CreateJoinTableAlertSite < ActiveRecord::Migration
  def change
    create_join_table :alerts, :sites do |t|
      # t.index [:alert_id, :site_id]
      # t.index [:site_id, :alert_id]
    end
  end
end
