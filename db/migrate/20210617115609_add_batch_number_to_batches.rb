class AddBatchNumberToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :batch_number, :string
  end
end
