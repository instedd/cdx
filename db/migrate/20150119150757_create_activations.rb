class CreateActivations < ActiveRecord::Migration
  def change
    create_table :activations do |t|
      t.references :activation_token, index: true

      t.timestamps
    end
  end
end
