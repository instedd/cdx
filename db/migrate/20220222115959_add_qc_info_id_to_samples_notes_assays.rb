class AddQcInfoIdToSamplesNotesAssays < ActiveRecord::Migration
  def change
    add_reference :samples, :qc_info, index: true
    add_reference :assay_attachments, :qc_info, index: true
    add_reference :notes, :qc_info, index: true
  end
end
