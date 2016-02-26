class AddCategoryToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :error_code, :string
    add_column :alerts, :category_type, :integer
    add_column :alerts, :aggregation_type, :integer, default:0
    remove_column :alerts, :receipients
  end
end
