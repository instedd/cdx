class ItemSearchPage < CdxPageBase
  class Result < SitePrism::Section
    def select
      root_element.click
    end
  end

  def perform_search(text)
    self.search.set text
    sleep 1
    self.wait_for_ajax
  end

  def search_and_select_first(text)
    perform_search text
    results.first.select
  end

  element :search, ".item-search input"

  sections :results, Result, ".item-search ul li"
end
