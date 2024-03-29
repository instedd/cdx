# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

if ENV['CI'] || ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter if ENV['CI']
  SimpleCov.start 'rails'
end

require 'cucumber/rails'
require 'machinist/active_record'

Dir[ File.dirname(__FILE__) + "/../../spec/support/*"].each {|file| require file }

# Capybara defaults to CSS3 selectors rather than XPath.
# If you'd prefer to use XPath, just uncomment this line and adjust any
# selectors in your step definitions to use the XPath syntax.
# Capybara.default_selector = :xpath

# By default, any exception happening in your Rails application will bubble up
# to Cucumber so that your scenario will fail. This is a different from how
# your application behaves in the production environment, where an error page will
# be rendered instead.
#
# Sometimes we want to override this default behaviour and allow Rails to rescue
# exceptions and display an error page (just like when the app is running in production).
# Typical scenarios where you want to do this is when you test your error pages.
# There are two ways to allow Rails to rescue exceptions:
#
# 1) Tag your scenario (or feature) with @allow-rescue
#
# 2) Set the value below to true. Beware that doing this globally is not
# recommended as it will mask a lot of errors for you!
#
ActionController::Base.allow_rescue = false

#needed for adding devices/sites to alert tests
Before { LocationService.fake! }

Before('@single_tenant') do
  Settings.single_tenant = true
end

After('@single_tenant') do
  Settings.single_tenant = false
end
