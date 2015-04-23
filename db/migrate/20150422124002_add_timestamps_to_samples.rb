class AddTimestampsToSamples < ActiveRecord::Migration
  def change
    add_column :samples, :created_at, :datetime
    add_column :samples, :updated_at, :datetime
  end
end
