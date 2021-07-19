class AddIsolateNameToSamples < ActiveRecord::Migration
  def change
    add_column :samples, :isolate_name, :string
    add_index :samples, :isolate_name
  end
end
