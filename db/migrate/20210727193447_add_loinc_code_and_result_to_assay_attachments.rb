class AddLoincCodeAndResultToAssayAttachments < ActiveRecord::Migration
  def up
    add_column :assay_attachments, :loinc_code, :string
    add_column :assay_attachments, :result, :string
    add_index :assay_attachments, :loinc_code unless index_exists?(:assay_attachments, :loinc_code)
    add_index :assay_attachments, :result unless index_exists?(:assay_attachments, :result)
  end

  def down
    remove_index :assay_attachments, :loinc_code if index_exists?(:assay_attachments, :loinc_code)
    remove_index :assay_attachments, :result if index_exists?(:assay_attachments, :result)

    remove_column :assay_attachments, :loinc_code
    remove_column :assay_attachments, :result
  end
end
