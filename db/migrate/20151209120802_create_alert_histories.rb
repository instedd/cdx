class CreateAlertHistories < ActiveRecord::Migration
  def change
    create_table :alert_histories do |t|
      t.boolean :read, default: false
      t.references :user, index: true
      t.references :alert, index: true
      t.references :test_result
      t.timestamps
    end
  end
end

