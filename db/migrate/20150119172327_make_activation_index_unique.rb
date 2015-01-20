class MakeActivationIndexUnique < ActiveRecord::Migration
  def change
    remove_index :activations, :activation_token_id
    add_index :activations, :activation_token_id, unique: true
  end
end
