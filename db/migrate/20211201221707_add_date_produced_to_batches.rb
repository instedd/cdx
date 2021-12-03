class AddDateProducedToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :date_produced, :datetime
    add_index :batches, :date_produced
  end
end
