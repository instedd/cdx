class AddOldBatchNumberToSamples < ActiveRecord::Migration
  def change
    add_column :samples, :old_batch_number, :string
  end
end
