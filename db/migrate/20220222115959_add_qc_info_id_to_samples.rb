class AddQcInfoIdToSamples < ActiveRecord::Migration
  def change
    add_reference :samples, :qc_info, index: true
  end
end
