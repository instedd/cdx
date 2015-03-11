class AddSampleUidHashToSamples < ActiveRecord::Migration
  def change
    add_column :samples, :sample_uid_hash, :string
  end
end
