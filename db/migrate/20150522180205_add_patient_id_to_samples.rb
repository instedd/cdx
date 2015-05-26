class AddPatientIdToSamples < ActiveRecord::Migration
  def change
    add_reference :samples, :patient, index: true
  end
end
