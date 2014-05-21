class CreateNewSubscribers < ActiveRecord::Migration
  def change
    create_table :subscribers do |t|
      t.integer :user_id
      t.string :name
      t.string :url
      t.text :filter
      t.text :fields
      t.timestamp :last_run_at

      t.timestamps
    end
  end
end
