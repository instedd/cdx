class AddTestResultUpdatedAtToAlertHistories < ActiveRecord::Migration
  def change
    add_column :alert_histories, :test_result_updated_at, :datetime
  end
end
