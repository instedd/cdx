class RemoveLaboratorySamplesAndTestQcAssays < ActiveRecord::Migration
  def change
    drop_table :laboratory_samples
    drop_table :test_qc_results
    drop_table :test_qc_result_assays
  end
end
