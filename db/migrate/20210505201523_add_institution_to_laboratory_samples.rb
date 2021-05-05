class AddInstitutionToLaboratorySamples < ActiveRecord::Migration
  def change
    add_reference :laboratory_samples, :institution, index: true, foreign_key: true
  end
end
