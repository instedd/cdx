class AddTreatmentWeeksToEncounters < ActiveRecord::Migration
  def change
    add_column :encounters, :treatment_weeks, :integer
    remove_column :encounters, :date_of_treatment, :date
  end
end
