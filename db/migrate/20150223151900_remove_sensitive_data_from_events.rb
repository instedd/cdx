class RemoveSensitiveDataFromEvents < ActiveRecord::Migration
  def change
    remove_column :events, :sensitive_data, :binary
  end
end
