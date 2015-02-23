class AddSampleToEvents < ActiveRecord::Migration
  def change
    add_column :events, :sample_id, :integer
  end
end
