class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.integer :work_group_id
      t.integer :device_id
      t.binary :data

      t.timestamps
    end
  end
end
