class CreateAssays < ActiveRecord::Migration
  def change
    create_table :assays do |t|
      t.references :sample, index: true, foreign_key: true
      t.attachment :picture
      t.timestamps null: false
    end
  end
end
