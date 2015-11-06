class NewEncounterPage < SitePrism::Page
  include CdxPageHelper

  set_url "/encounters/new"

  element :append_sample, "a", text: /\AAppend sample\z/
  element :save, ".btn-primary"

  def open_append_sample
    append_sample.click
    yield ItemSearchPage.new if block_given?
  end

  def submit
    save.click
    wait_for_submit
  end
end
