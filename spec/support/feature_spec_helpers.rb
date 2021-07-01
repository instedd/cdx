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
  # alias_method_chain :click, :ajax
  alias_method :click_without_ajax, :click
  alias_method :click, :click_with_ajax

  # remove targe=_blank before clicking
  def click_with_target_removed
    page.evaluate_script('$("a[target=_blank]").attr("target", null);')
    click_without_target_removed
  end
  # alias_method_chain :click, :target_removed
  alias_method :click_without_target_removed , :click
  alias_method :click, :click_with_target_removed

  def page
    session
  end
end
