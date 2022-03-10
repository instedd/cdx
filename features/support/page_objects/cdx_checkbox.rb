class CdxCheckbox < SitePrism::Section
  def set(value)
    if value
      check
    else
      uncheck
    end
  end

  def value
    checked?
  end

  private

  def check
    return if checked?
    root_element.click
  end

  def uncheck
    return unless checked?
    root_element.click
  end

  def checked?
    checkbox_field.checked?
  end

  def checkbox_field
    parent_page.find("##{root_element['for']}", visible: false)
  end
end
