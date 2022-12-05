module IconHelper
  ICON_PATH = Rails.root.join("app/assets/images/icons")

  def icon_tag(name, **attributes)
    if attributes[:class].is_a?(Enumerable)
      attributes[:class] << "icon-svg"
    else
      attributes[:class] = "icon-svg #{attributes[:class]}"
    end

    content_tag(:span, **attributes) do
      raw File.read(ICON_PATH.join("#{name}.svg"))
    end
  end
end
