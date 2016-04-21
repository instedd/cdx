class AddDeletedAtToEntities < ActiveRecord::Migration
  def change
    %W(test_results sample_identifiers samples encounters patients).each do |table|
      add_column table, :deleted_at, :datetime
      add_index  table, :deleted_at
    end
  end
end
