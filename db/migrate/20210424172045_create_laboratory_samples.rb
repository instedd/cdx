class CreateLaboratorySamples < ActiveRecord::Migration
  def change
    create_table :laboratory_samples do |t|
      t.string :uuid

      t.timestamps null: false
    end
  end
end
