class CdxPageBase < SitePrism::Page
  include CdxPageHelper

  class NavigationContextSection < SitePrism::Section
    def select(text)
      click_link text
    end
  end

  class ConfirmationSection < SitePrism::Section
    element :delete, :button, 'Delete'
  end

  element :navigation_context_handle, "#nav-context"
  section :navigation_context, NavigationContextSection, "#context_side_bar"
  element :primary, ".btn-primary"
  element :secondary, ".btn-secondary"
  element :content, ".content", match: :first
  element :logout_link, :link, "Log out"
  section :confirmation, ConfirmationSection, '[data-react-class="ConfirmationModal"]'

  def logout
    logout_link.trigger('click')
    wait_for_submit
  end

  def get_context_picker
    yield navigation_context
  end

  def close_context_picker
    navigation_context_handle.trigger('click')
  end

  def submit
    primary.click
    wait_for_submit
  end

  def press_secondary_button
    secondary.click
    wait_for_submit
  end

  def update_filters
    within filters do
      yield
    end
    self.wait_for_submit
  end

  def accept_confirm
    page.evaluate_script('window.__old_confirm = window.confirm;')
    page.evaluate_script('window.confirm = function() { return true; };')
    yield
    page.evaluate_script('window.confirm = window.__old_confirm;')
  end

  def success?
    status_code == 200
  end

  def forbidden?
    status_code == 403
  end
end
