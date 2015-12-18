class AddTimestampsToSampleIdentifiers < ActiveRecord::Migration
  def up
    change_table :sample_identifiers do |t|
      t.timestamps
    end

    connection.execute <<-SQL
      UPDATE sample_identifiers
      SET created_at = (
        SELECT samples.created_at FROM samples WHERE samples.id = sample_identifiers.sample_id
      ), updated_at = (
        SELECT samples.updated_at FROM samples WHERE samples.id = sample_identifiers.sample_id
      )
    SQL
  end

  def down
    add_column :sample_identifiers, :created_at
    add_column :sample_identifiers, :updated_at
  end
end
