class TestsSchema < EntitySchema
  def scopes
    Cdx::Fields.test.core_field_scopes
  end
end
