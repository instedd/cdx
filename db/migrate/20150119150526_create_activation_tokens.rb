class CreateActivationTokens < ActiveRecord::Migration
  def change
    create_table :activation_tokens do |t|
      t.string :value
      t.string :device_secret_key
      t.references :device, index: true

      t.timestamps
    end
  end
end
