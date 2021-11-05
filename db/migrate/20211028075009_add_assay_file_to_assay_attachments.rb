class AddAssayFileToAssayAttachments < ActiveRecord::Migration
  def change
    add_reference :assay_attachments, :assay_file, index: true
  end
end
