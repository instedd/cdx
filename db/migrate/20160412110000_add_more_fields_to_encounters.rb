class AddMoreFieldsToEncounters < ActiveRecord::Migration
  def change
    add_column :encounters, :exam_reason, :string
    add_column :encounters, :tests_requested, :string
    add_column :encounters, :coll_sample_type, :string
    add_column :encounters, :coll_sample_other, :string
    add_column :encounters, :diag_comment, :string
    add_column :encounters, :date_of_treatment, :date
    add_column :encounters, :testdue_date, :date
  end
end
