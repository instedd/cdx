class CdxSelect < SitePrism::Section
  def set(text)
    select_elem.find(".Select-placeholder").click
    select_elem.find(".Select-option", text: text).click
  end

  def value
    select_elem.find(".Select-placeholder").text
  end

  private

  def select_elem
    @select_elem ||= begin
      elem = root_element
      
      while elem.all(".Select").empty?
        elem = elem.find(:xpath, '..')
      end

      elem.find(".Select")
    end
  end
end
