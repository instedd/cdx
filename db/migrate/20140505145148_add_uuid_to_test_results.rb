class AddUuidToTestResults < ActiveRecord::Migration
  def change
    add_column :test_results, :uuid, :string
  end
end
