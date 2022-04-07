require 'selenium/webdriver'

if defined?(Cucumber)
  require 'capybara/cucumber'
  require 'capybara-screenshot/cucumber'
else
  require 'capybara/rspec'
  require 'capybara-screenshot/rspec'
end

# Configure the capybara test server on an IP accessible from the network, so we
# can use a remote selenium server from another compose service (or the host).
ENV['SERVER_HOST'] ||= Socket.ip_address_list.find(&:ipv4_private?).ip_address
ENV['SERVER_PORT'] ||= '4000'
ENV['HEADLESS'] ||= 'true'
ENV['SELENIUM_URL'] ||= 'http://selenium:4444/'

Capybara.configure do |config|
  config.server = :puma, { Silent: true }
  config.server_host = ENV["SERVER_HOST"]
  config.server_port = ENV["SERVER_PORT"].to_i
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
# We must also tell SitePrism to respect this implicit wait time.
#
# WARNING: this also affects matchers that want to verify that an element
# doesn't exist, in which case you should override the wait time!
Capybara.default_max_wait_time = 5

SitePrism.configure do |config|
  config.use_implicit_waits = true
end
