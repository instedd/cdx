class AddInstructionToSamples < ActiveRecord::Migration[5.0]
  def change
    add_column :samples, :instruction, :string
  end
end
