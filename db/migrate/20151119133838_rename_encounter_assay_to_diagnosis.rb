class RenameEncounterAssayToDiagnosis < ActiveRecord::Migration

  class MigrationEncounter < ActiveRecord::Base
    self.table_name = 'encounters'
    serialize :core_fields, Hash
  end

  def up
    MigrationEncounter.find_each do |encounter|
      assays = encounter.core_fields.delete('assays')
      next if assays.nil?
      encounter.core_fields['diagnosis'] = assays
      encounter.save!
    end
  end

  def down
    MigrationEncounter.find_each do |encounter|
      assays = encounter.core_fields.delete('diagnosis')
      next if assays.nil?
      encounter.core_fields['assays'] = assays
      encounter.save!
    end
  end

end
