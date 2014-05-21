class DeleteSubscribers < ActiveRecord::Migration
  def up
    drop_table :subscribers
  end

  def down
    create_table :subscribers do |t|
      t.string :name
      t.string :callback_url
      t.references :work_group, index: true

      t.timestamps
    end
  end
end
