class NewEncounterPage < CdxPageBase
  set_url "/encounters/new"

  element :append_sample, :link, "Append sample"

  def open_append_sample
    append_sample.click
    yield ItemSearchPage.new if block_given?
  end
end
