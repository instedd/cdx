class AddLoincCodeToAssayAttachments < ActiveRecord::Migration
  def change
    add_reference :assay_attachments, :loinc_code, index: true, foreign_key: true
  end
end
