class AddBatchToLaboratorySamples < ActiveRecord::Migration
  def change
    add_reference :laboratory_samples, :batch, index: true, foreign_key: true
  end
end
