class AddSiteIdToSampleIdentifiers < ActiveRecord::Migration
  def up
    add_column :sample_identifiers, :site_id, :integer

    connection.execute <<-SQL
      UPDATE sample_identifiers
      SET site_id = (
        SELECT test_results.site_id
        FROM test_results
        WHERE sample_identifiers.id = test_results.sample_identifier_id
        LIMIT 1)
    SQL
  end

  def down
    remove_column :sample_identifiers, :site_id
  end
end
