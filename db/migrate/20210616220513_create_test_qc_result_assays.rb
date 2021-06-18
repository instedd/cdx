class CreateTestQcResultAssays < ActiveRecord::Migration
  def change
    create_table :test_qc_result_assays do |t|
      t.references :test_qc_result, index: true
      t.attachment :picture
      t.timestamps null: false
    end
  end
end
