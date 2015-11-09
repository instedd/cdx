module CdxPageHelper
  # source: https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
  def wait_for_ajax
    Timeout.timeout(Capybara.default_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def wait_for_submit
    sleep 0.5
    wait_for_ajax
  end

  def finished_all_ajax_requests?
    return true unless page.current_url.start_with?("http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}")
    page.evaluate_script('jQuery.active').zero?
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

  # remove targe=_blank before clicking
  def click_with_target_removed
    page.evaluate_script('$("a[target=_blank]").attr("target", null);')
    click_without_target_removed
  end
  alias_method_chain :click, :target_removed

  def page
    session
  end
end
