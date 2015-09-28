class FillEntityIdInSamples < ActiveRecord::Migration

  class SampleForMigration < ActiveRecord::Base
    self.table_name = "samples"
    serialize :core_fields, Hash
  end

  def up
    SampleForMigration.all.each do |sample|
      sample.entity_id = sample.core_fields["id"]
      sample.save!
    end
  end

  def down
  end
end
