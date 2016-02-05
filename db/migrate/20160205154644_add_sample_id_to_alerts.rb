class AddSampleIdToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :sample_id, :string
  end
end
