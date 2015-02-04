class RenameFilterParamsAsQuery < ActiveRecord::Migration
  def change
    rename_column(:filters, :params, :query)
  end
end
