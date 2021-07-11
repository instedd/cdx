class AddSampleToNotes < ActiveRecord::Migration
  def change
    add_reference :notes, :sample, index: true, foreign_key: true
    remove_reference :notes, :laboratory_sample, index: true
  end
end
