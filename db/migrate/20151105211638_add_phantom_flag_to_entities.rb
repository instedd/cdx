class AddPhantomFlagToEntities < ActiveRecord::Migration
  def up
    add_column :patients, :is_phantom, :boolean, default: true
    add_column :encounters, :is_phantom, :boolean, default: true
    add_column :samples, :is_phantom, :boolean, default: true

    connection.execute <<-SQL
      UPDATE patients
      SET is_phantom = FALSE
      WHERE entity_id_hash IS NOT NULL
    SQL

    connection.execute <<-SQL
      UPDATE encounters
      SET is_phantom = FALSE
      WHERE entity_id IS NOT NULL
    SQL

    connection.execute <<-SQL
      UPDATE samples
      SET is_phantom = FALSE
      WHERE EXISTS (SELECT 1
             FROM sample_identifiers
             WHERE sample_identifiers.sample_id = samples.id
             AND sample_identifiers.entity_id IS NOT NULL)
    SQL
  end

  def down
    remove_column :patients, :is_phantom
    remove_column :encounters, :is_phantom
    remove_column :samples, :is_phantom
  end
end
