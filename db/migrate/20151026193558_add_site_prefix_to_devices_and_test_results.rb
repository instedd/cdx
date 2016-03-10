class AddSitePrefixToDevicesAndTestResults < ActiveRecord::Migration
  def change
    add_column :devices, :site_prefix, :string
    add_column :test_results, :site_prefix, :string
  end
end
