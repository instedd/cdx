class EncounterFormPage < CdxPageBase
  class EncounterDiagnosis < SitePrism::Section
    class AssayEditor < SitePrism::Section
      section :result, CdxSelect, ".Select"
      element :quant, ".quantitative"
    end

    sections :assays, AssayEditor, ".row:first-child"
  end

  section :diagnosis, EncounterDiagnosis, ".assays-editor"
  element :append_sample, :link, "Append sample"
  element :add_tests, :link, "Add tests"

  def open_append_sample
    append_sample.click
    modal = ItemSearchPage.new
    yield modal if block_given?
    modal
  end

  def open_add_tests
    add_tests.click
    modal = ItemSearchPage.new
    yield modal if block_given?
    modal
  end
end

class NewEncounterPage < EncounterFormPage
  set_url "/encounters/new"
end

class EditEncounterPage < EncounterFormPage
  set_url "/encounters/{id}/edit"
end
