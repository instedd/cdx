class AddEntityIdToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :entity_id, :string
  end
end
