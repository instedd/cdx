class CdxPageBase < SitePrism::Page
  include CdxPageHelper

  class NavigationContextSection < SitePrism::Section
    def select(text)
      click_link text
    end
  end

  element :navigation_context_handle, "#nav-context"
  section :navigation_context, NavigationContextSection, "#context_side_bar"
  element :primary, ".btn-primary"

  def open_context_picker
    navigation_context_handle.click
    yield navigation_context
  end

  def submit
    primary.click
    wait_for_submit
  end
end
