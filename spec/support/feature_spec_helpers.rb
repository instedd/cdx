module FeatureSpecHelpers
  extend ActiveSupport::Concern

  included do
    metadata[:js] = true
    metadata[:elasticsearch] = true
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
      page.form.user_name.set user.email
      page.form.password.set user.password
      page.form.login.click
    end
  end

  def goto_page(klass, args = {})
    page = klass.new
    page.load args
    yield page if block_given?
  end

  def expect_page(klass)
    page = klass.new
    expect(page).to be_displayed
    yield page if block_given?
  end

  def snapshot
    screenshot_and_open_image
  end
end

class Capybara::Node::Element
  include CdxPageHelper

  # Make every click in element wait for ajax to complete
  def click_with_ajax
    click_without_ajax
    wait_for_ajax
  end
  alias_method_chain :click, :ajax

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
