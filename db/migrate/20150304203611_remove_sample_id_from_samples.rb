class RemoveSampleIdFromSamples < ActiveRecord::Migration
  def change
    remove_column :samples, :sample_id, :string
  end
end
