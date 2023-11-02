class AddOriginalBatchIdToSamples < ActiveRecord::Migration
  def change
    add_column :samples, :original_batch_id, :integer

    Sample.preload(:batch).find_each do |sample|
      if sample.batch
        sample.original_batch_id = sample.batch.id
        sample.save
      elsif sample.box_id && sample.old_batch_number
        institution_ids = TransferPackage
          .select(:sender_institution_id)
          .joins(:box_transfers)
          .where(box_transfers: { box_id: sample.box_id })
          .distinct
      
        original_batch = Batch.where(
          institution_id: institution_ids,
          batch_number: sample.old_batch_number
        ).take
        if original_batch
          sample.original_batch_id = original_batch.id
          sample.save
        end
      end
    end
  end
end
