class CdxSelect < SitePrism::Section
  def set(text)
    select_elem.find(".Select-placeholder").click
    select_elem.find(".Select-option", text: text).click
  end

  def value
    select_elem.find(".Select-placeholder").text
  end

  def options
    select_elem.find(".Select-placeholder").click
    res = select_elem.all(:css, ".Select-option").each.map(&:text).to_a
    select_elem.find(".Select-placeholder").click

    return res
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
