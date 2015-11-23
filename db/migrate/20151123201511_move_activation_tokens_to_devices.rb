class MoveActivationTokensToDevices < ActiveRecord::Migration
  class ActivationToken < ActiveRecord::Base
    has_one :activation, dependent: :destroy

    def used?
      !activation.nil?
    end
  end

  class Device < ActiveRecord::Base
    has_one :activation_token_object, class_name: "ActivationToken", dependent: :destroy
  end

  def up
    add_column :devices, :activation_token, :string

    Device.find_each do |device|
      activation_token = device.activation_token_object
      if activation_token && !activation_token.used?
        device.activation_token = activation_token.value
        device.save!
      end
    end

    drop_table :activation_tokens
    drop_table :activations
  end

  def down
    create_table :activation_tokens do |t|
      t.string :value
      t.string :client_id
      t.references :device, index: true

      t.timestamps
    end
    add_index :activation_tokens, :value, unique: true

    create_table :activations do |t|
      t.references :activation_token, index: true

      t.timestamps
    end

    remove_column :devices, :activation_token
  end
end
