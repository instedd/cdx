class AddSiteToBatches < ActiveRecord::Migration
  def change
    add_reference :batches, :site, index: true, foreign_key: true
    add_column :batches, :site_prefix, :string
  end
end
