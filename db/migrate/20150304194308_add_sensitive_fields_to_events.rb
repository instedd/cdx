class AddSensitiveFieldsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :sensitive_data, :binary
  end
end
