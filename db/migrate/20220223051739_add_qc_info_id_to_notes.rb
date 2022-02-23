class AddQcInfoIdToNotes < ActiveRecord::Migration
  def change
    add_reference :notes, :qc_info, index: true
  end
end
