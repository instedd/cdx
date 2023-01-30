class CdxSelect < SitePrism::Section
  def set(text)
    select_elem.find(".Select-placeholder").click
    select_elem.find(".Select-option", text: text).click
  end

  def set_exact(text)
    select_elem.find(".Select-placeholder").click
    select_elem.find(".Select-option", text: text, :match => :prefer_exact).click
  end

  def set_exact_multi(text)
    select_elem.find(".Select-placeholder").click
    select_elem.find(".Select-option", text: text, :match => :prefer_exact).click
  end

  def paste(text)
    select_elem.find(".Select-control").click
    select_elem.find(".Select-input input").set(text)
    select_elem.wait_for_ajax
  end

  def type(text)
    select_elem.find(".Select-control").click
    text.each_char do |char|
      parent_page.find("body").native.send_key char
    end
    select_elem.wait_for_ajax
  end

  def type_and_select(text)
    type(text)
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
      if root_element[:class].split(/\s+/).include?("Select")
        root_element
      else
        # search until a parent's descendant matches '.Select' (very slow)
        parent = root_element

        until element = parent.first(".Select", minimum: 0, maximum: 1)
          parent = parent.find(:xpath, "..")
        end

        element
      end
    end
  end
end
