class AddIndexToActivationTokenValue < ActiveRecord::Migration
  def change
    add_index :activation_tokens, :value, unique: true
  end
end
