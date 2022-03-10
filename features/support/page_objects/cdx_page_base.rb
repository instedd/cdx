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
  element :content, ".content", match: :first
  element :user_menu, ".user"
  element :logout_link, :link, "Log out"
  section :confirmation, ConfirmationSection, '[data-react-class="ConfirmationModal"]'

  def logout
    user_menu.click
    logout_link.click
    wait_for_submit
  end

  def get_context_picker
    yield navigation_context
  end

  def close_context_picker
    navigation_context_handle.click
  end

  def submit
    primary.click
    wait_for_submit
  end

  def success?
    # we can't test the page's HTTP status code with Selenium WebDriver so we
    # merely test that the `user_menu` element is present on page:
    !!user_menu
  rescue
    false
  end

  # FIXME: sometimes we must force some manual retry in addition to
  #        Capybara.default_max_wait_time
  def retry_block(attempts: 1, sleep_for: 0.5)
    begin
      yield
    rescue Capybara::ElementNotFound => ex
      if attempts > 0
        attempts -= 1
        sleep(sleep_for)
        retry
      else
        raise ex
      end
    end
  end
end
