class CreateAssayFile < ActiveRecord::Migration
  def change
    create_table :assay_files do |t|
      t.belongs_to :assay_attachment, index: true
      t.attachment :picture
      t.timestamps null: false
    end
  end
end
