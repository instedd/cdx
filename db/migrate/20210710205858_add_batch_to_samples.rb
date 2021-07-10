class AddBatchToSamples < ActiveRecord::Migration
  def change
    add_reference :samples, :batch, index: true, foreign_key: true
  end
end
