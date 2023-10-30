class AddOriginalBatchIdToSamples < ActiveRecord::Migration
  def change
    add_column :samples, :original_batch_id, :integer

    Sample.preload(:batch).find_each do |sample|
      batch = sample.batch || Batch.find_by(batch_number: sample.old_batch_number)
      if batch
        sample.original_batch_id = batch.id
        sample.save
      end
    end
  end
end
