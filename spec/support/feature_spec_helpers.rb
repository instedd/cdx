module FeatureSpecHelpers
  extend ActiveSupport::Concern

  included do
    metadata[:js] = true
    metadata[:elasticsearch] = true

    after(:each) do
      next unless session = Capybara.current_session

      if session.driver.respond_to?(:log)
        session.driver.browser.manage.logs.get(:browser)
          .each { |log| puts "JS: #{log.level} #{log.message}" }
      else
        # geckodriver doesn't implement the log interface (sigh)
        session.execute_script("return window.__cdx_logs;")
          .each { |log| puts "JS: #{log.join(" ")}" }
      end
    end
  end

  def process(args = {})
    process_plain args.deep_merge({test:{assays:[condition: "flu_a", name: "flu_a", result: "positive"]}})
  end

  def process_plain(args)
    dm = DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(args)
    refresh_index
    dm.test_results.first
  end

  def sign_in(user)
    if user.password.nil?
      # change password of user
      user.password = 'password'
      user.password_confirmation = 'password'
      user.save!
    end

    goto_page HomePage do |page|
      unless page.has_form?
        page.user_menu.icon.click
        page.user_menu.logout.click
      end
      page.form.user_name.set user.email
      page.form.password.set user.password
      page.form.login.click
    end
  end

  def goto_page(klass, args = {})
    page = klass.new

    attempts = 0
    begin
      page.load args
    rescue Net::ReadTimeout
      # Selenium and/or the browser may not be ready yet (especially on CI) so
      # let's retry a few times...
      if (attempts += 1) == 3
        retry
      else
        raise
      end
    end

    yield page if block_given?
  end

  def expect_page(klass)
    page = klass.new
    unless page.displayed?
      fail "Expected `#{page.inspect}` to be displayed, got `#{page.page.current_url}`"
    end
    yield page if block_given?
  end

  def snapshot
    screenshot_and_open_image
  end
end

module CdxClickWithAjax
  # Make every click in element wait for ajax to complete
  def click
    super
    wait_for_ajax
  end
end

class Capybara::Node::Element
  include CdxPageHelper
  prepend CdxClickWithAjax

  # Removes the `target` attribute before clicking a link. Useful to remove an
  # "_blank" target for example.
  def remove_target_and_click
    # The expression returns null otherwise we get a "Cyclic object value" in
    # Firefox, this is caused by the driver trying to return the objects
    # serialized as JSON, but the raw A elements have cyclic references, causing
    # JSON.stringify to crash.
    page.evaluate_script("$('a').removeAttr('target'), null")
    click
  end

  def page
    session
  end
end
