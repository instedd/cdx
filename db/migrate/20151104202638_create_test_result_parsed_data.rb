class CreateTestResultParsedData < ActiveRecord::Migration
  def change
    create_table :test_result_parsed_data do |t|
      t.integer :test_result_id
      t.binary :data

      t.timestamps
    end
  end
end
