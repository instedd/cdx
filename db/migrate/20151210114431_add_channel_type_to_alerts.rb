class AddChannelTypeToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :channel_type, :integer, default:0
  end
end
