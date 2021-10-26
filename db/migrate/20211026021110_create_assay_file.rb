class CreateAssayFile < ActiveRecord::Migration
  def change
    create_table :assay_files do |t|
      t.references :assay_attachment, index: true, foreign_key: true
      t.attachment :picture
      t.timestamps null: false
    end
  end
end
