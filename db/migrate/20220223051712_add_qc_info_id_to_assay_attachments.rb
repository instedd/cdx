class AddQcInfoIdToAssayAttachments < ActiveRecord::Migration
  def change
    add_reference :assay_attachments, :qc_info, index: true
  end
end
