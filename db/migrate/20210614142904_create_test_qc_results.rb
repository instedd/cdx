class CreateTestQcResults < ActiveRecord::Migration
  def change
    create_table :test_qc_results do |t|
      t.references :laboratory_sample, index: true
      t.attachment :picture
      t.timestamps null: false
    end
  end
end
