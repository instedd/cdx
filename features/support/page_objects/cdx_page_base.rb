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
  element :content, ".content", match: :first

  def open_context_picker
    navigation_context_handle.click
    yield navigation_context
  end

  def submit
    primary.click
    wait_for_submit
  end

  def success?
    status_code == 200
  end

  def forbidden?
    status_code == 403
  end
end
