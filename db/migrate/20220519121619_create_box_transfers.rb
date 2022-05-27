class CreateBoxTransfers < ActiveRecord::Migration
  def change
    create_table :box_transfers do |t|
      t.references :box, index: true, foreign_key: true, null: false
      t.references :transfer_package, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end
  end
end
