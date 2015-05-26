class AddPatientIdToEvents < ActiveRecord::Migration
  def change
    add_reference :events, :patient, index: true
  end
end
