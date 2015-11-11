class CdxTable < SitePrism::Section
  class Item < SitePrism::Section
    def click
      root_element.click
    end
  end

  sections :items, Item, "tbody tr"
end
