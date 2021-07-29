class AddLoincCodeAndResultToAssayAttachments < ActiveRecord::Migration
  def change
    add_column :assay_attachments, :loinc_code, :string
    add_column :assay_attachments, :result, :string
    add_index :assay_attachments, :loinc_code
    add_index :assay_attachments, :result
  end
end
