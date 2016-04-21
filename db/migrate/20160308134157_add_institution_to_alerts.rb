class AddInstitutionToAlerts < ActiveRecord::Migration
  def change
    add_reference :alerts, :institution, index: true, foreign_key: true
  end
end
