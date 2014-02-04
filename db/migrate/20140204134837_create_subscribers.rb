class CreateSubscribers < ActiveRecord::Migration
  def change
    create_table :subscribers do |t|
      t.string :name
      t.string :callback_url
      t.references :work_group, index: true

      t.timestamps
    end
  end
end
