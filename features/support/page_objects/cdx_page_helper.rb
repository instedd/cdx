module CdxPageHelper
  # source: https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
  def wait_for_ajax
    Timeout.timeout(Capybara.default_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end

  def remove_target_blank!
    page.evaluate_script('$("a[target=_blank]").attr("target", null);')
  end  
end
