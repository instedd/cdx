class RemoveLoincCodeFromAssayAttachments < ActiveRecord::Migration
  def change
    remove_column :assay_attachments, :loinc_code, :string
  end
end