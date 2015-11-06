class NewEncounterPage < CdxPageBase
  set_url "/encounters/new"

  element :append_sample, :link, "Append sample"
  element :add_tests, :link, "Add tests"

  def open_append_sample
    append_sample.click
    yield ItemSearchPage.new if block_given?
  end

  def open_add_tests
    add_tests.click
    yield ItemSearchPage.new if block_given?
  end
end
