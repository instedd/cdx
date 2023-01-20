module CdxPageHelper
  # source: https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      until finished_all_ajax_requests?
        sleep 0.01
      end
    end
  end

  def wait_for_submit
    sleep 0.5
    wait_for_ajax
  end

  def finished_all_ajax_requests?
    return true unless page.current_host == test_server_host
    page.evaluate_script('window.jQuery && jQuery.active').try(&:zero?)
  end

  private

  # The server is `nil` for `:rack_test` driver which uses www.example.com internally:
  def test_server_host
    @test_server_host ||=
      if server = Capybara.current_session.server
        "#{server.host}:#{server.port}"
      else
        "www.example.com"
      end
  end
end
