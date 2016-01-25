class CdxSelect < SitePrism::Section
  def set(text)
    select_elem.find(".Select-placeholder").click
    select_elem.find(".Select-option", text: text).click
  end

  def set_exact(text)
    select_elem.find(".Select-placeholder").click
    select_elem.find(".Select-option", text: text, :match => :prefer_exact).click
  end
  
  # https://www.bountysource.com/issues/3457481-scroll-click-firing-at-wrong-coordinates-poltergeist-detected-another-element-with-css-selector-at-this-position
  def set_exact_multi(text)
    select_elem.find(".Select-placeholder").trigger('click')
    #  select_elem.find(".Select-option", text: text, :match => :prefer_exact).click 
  end
  
  def type_and_select(text)
    select_elem.find(".Select-control").click
    text.each_char do |char|
      page.find("body").native.send_key char
    end

    select_elem.wait_for_ajax
    select_elem.find(".Select-option").click
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