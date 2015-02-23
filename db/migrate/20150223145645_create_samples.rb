class CreateSamples < ActiveRecord::Migration
  def change
    create_table :samples do |t|
      t.string :sample_id
      t.string :uuid
      t.binary :sensitive_data
    end
  end
end
