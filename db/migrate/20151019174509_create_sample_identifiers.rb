class CreateSampleIdentifiers < ActiveRecord::Migration
  def up
    create_table :sample_identifiers do |t|
      t.integer :sample_id
      t.string :entity_id, limit: 255
      t.string :uuid,      limit: 255
    end

    add_index :sample_identifiers, :sample_id
    add_index :sample_identifiers, :entity_id
    add_index :sample_identifiers, :uuid, unique: true

    add_column    :test_results, :sample_identifier_id, :integer
    add_index     :test_results, :sample_identifier_id

    connection.execute <<-SQL
      INSERT INTO sample_identifiers(sample_id, entity_id, uuid)
      SELECT id as sample_id, entity_id, uuid
      FROM samples
    SQL

    connection.execute <<-SQL
      UPDATE test_results
      SET sample_identifier_id = (
        SELECT sample_identifiers.id
        FROM sample_identifiers
        WHERE sample_identifiers.sample_id = test_results.sample_id
      )
    SQL

    remove_column :test_results, :sample_id, :integer

    remove_column :samples, :entity_id, :string, limit: 255
    remove_column :samples, :uuid,      :string, limit: 255
  end

  def down
    add_column :samples, :entity_id, :string, limit: 255
    add_column :samples, :uuid,      :string, limit: 255

    add_column :test_results, :sample_id, :integer

    connection.execute <<-SQL
      UPDATE samples
      SET entity_id = (
        SELECT entity_id
        FROM sample_identifiers
        WHERE sample_identifiers.sample_id = samples.id
        ORDER BY uuid
        LIMIT 1
      ),
      uuid = (
        SELECT uuid
        FROM sample_identifiers
        WHERE sample_identifiers.sample_id = samples.id
        ORDER BY uuid
        LIMIT 1
      )
    SQL

    connection.execute <<-SQL
      UPDATE test_results
      SET sample_id = (
        SELECT sample_identifiers.sample_id
        FROM sample_identifiers
        WHERE sample_identifiers.id = test_results.sample_identifier_id
      )
    SQL

    remove_column :test_results, :sample_identifier_id, :integer
    drop_table :sample_identifiers
  end
end
