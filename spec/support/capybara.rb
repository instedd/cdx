require 'selenium/webdriver'

if defined?(Cucumber)
  require 'capybara/cucumber'
  require 'capybara-screenshot/cucumber'
else
  require 'capybara/rspec'
  require 'capybara-screenshot/rspec'
end

test_env_number = (ENV["TEST_ENV_NUMBER"].presence || 1).to_i

# Configure the capybara test server on an IP accessible from the network, so we
# can use a remote selenium server from another compose service (or the host).
ENV['SERVER_HOST'] ||= Socket.ip_address_list.find(&:ipv4_private?).ip_address
ENV['SERVER_PORT'] ||= (4000 + test_env_number).to_s
ENV['HEADLESS'] ||= 'true'
ENV["SELENIUM_URL"] = (ENV["SELENIUM_URL"] || "http://cdx-selenium-%{test_env_number}:4444/").gsub("%{test_env_number}", test_env_number.to_s)

Capybara.configure do |config|
  config.server = :puma, { Silent: true }
  config.server_host = ENV["SERVER_HOST"]
  config.server_port = ENV["SERVER_PORT"].to_i
end

# Resolve domain name as IP (mainly for geckodriver to accept any connections)
begin
  selenium_uri = URI(ENV["SELENIUM_URL"])
  selenium_uri.host = Addrinfo.tcp(selenium_uri.host, selenium_uri.port).ip_address
  ENV["SELENIUM_URL"] = selenium_uri.to_s
rescue SocketError
  STDERR.puts "WARNING: can't reach selenium server on #{ENV["SELENIUM_URL"]}"
end

if defined?(ALLOWED_WEBMOCK_HOSTS)
  ALLOWED_WEBMOCK_HOSTS << /http:\/\/#{Capybara.server_host}:#{Capybara.server_port}/
  ALLOWED_WEBMOCK_HOSTS << /^#{Regexp.escape(ENV["SELENIUM_URL"])}/
end

Capybara.register_driver :selenium do |app|
  case ENV['BROWSER']
  when 'chrome'
    browser = :chrome
    options = ::Selenium::WebDriver::Chrome::Options.new(args: %w[--disable-gpu --no-sandbox])
    options.args << "--headless" if ENV['HEADLESS'] == "true"
  else
    browser = :firefox
    options = ::Selenium::WebDriver::Firefox::Options.new
    options.args << "--headless" if ENV['HEADLESS'] == "true"
  end

  Capybara::Selenium::Driver.new(app, browser: browser, options: options, url: ENV['SELENIUM_URL'])
end

# NOTE: consider using :rack_test when possible because it's _much_ faster
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium

# Avoids some random errors with race conditions where elements don't appear
# quickly in the DOM after submitting a form for example, by introducing an
# implicit 5 seconds timeout to continuously retry the finder.
#
# WARNING: this also affects matchers that want to verify that an element
# doesn't exist, in which case you should override the wait time!
Capybara.default_max_wait_time = 2
