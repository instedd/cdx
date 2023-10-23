class AddOriginalBatchIdToSamples < ActiveRecord::Migration
  def change
    add_column :samples, :original_batch_id, :integer
  end
end
