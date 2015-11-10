class CdxSelect < SitePrism::Section
  def set(text)
    find(".Select-placeholder").click
    find(".Select-option", text: text).click
  end

  def value
    find(".Select-placeholder").text
  end
end
