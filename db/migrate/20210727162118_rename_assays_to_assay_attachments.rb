class RenameAssaysToAssayAttachments < ActiveRecord::Migration
  def change
    rename_table :assays, :assay_attachments
  end
end
