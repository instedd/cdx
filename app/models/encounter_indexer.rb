class EncounterIndexer < EntityIndexer
  attr_reader :encounter

  def initialize encounter
    super("encounter")
    @encounter = encounter
  end

  def after_index(options)
    # Nothing
  end

  def document_id
    encounter.uuid
  end

  def type
    'encounter'
  end

  def fields_to_index
    return {
      'institution' => institution_fields(encounter.institution),
      'site'        => site_fields(encounter.site),
      'encounter'   => encounter_fields(encounter),
      'patient'     => patient_fields(encounter.patient)
    }
  end
end
