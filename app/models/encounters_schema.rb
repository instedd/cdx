class EncountersSchema < EntitySchema
  def scopes
    Cdx::Fields.encounter.core_field_scopes
  end
end
