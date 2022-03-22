# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require "bundler/setup"

if ENV['CI'] || ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.command_name ENV['FEATURES'] == 'true' ? 'Rspec Features' : 'Rspec'
  SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter if ENV['CI']
  SimpleCov.start 'rails'
end

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/collection_matchers'
require 'coffee_script'
require 'capybara/rspec'

require 'webmock/rspec'
ALLOWED_WEBMOCK_HOSTS = [/elasticsearch/]

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("features/support/page_objects/*.rb")].each {|f| require f}
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

WebMock.disable_net_connect!(:allow_localhost => true, allow: ALLOWED_WEBMOCK_HOSTS.compact)

# This is to make machinist work with Rails 4
class ActiveRecord::Reflection::AssociationReflection
  def primary_key_name
    foreign_key
  end
end

RSpec.configure do |config|
  config.render_views
  config.infer_spec_type_from_file_location!

  config.mock_with :rspec do |mocks|
    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
  end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # Store last run failures to support --only-failures option
  config.example_status_persistence_file_path = 'examples.txt'

  config.include Devise::TestHelpers, :type => :controller
  config.include DefaultParamsHelper, :type => :controller
  config.extend SpecFixtures
  config.include ManifestSpecHelper
  config.include CdxFieldsHelper
  config.include FeatureSpecHelpers, :type => :feature

  config.before(:suite) do
    LocationService.fake!
  end

  config.before(:each) do
    ActionMailer::Base.deliveries.clear
  end

  if ENV['FEATURES'] == 'true'
    config.pattern = "spec/features/**/*_spec.rb"
  else
    config.exclude_pattern = "spec/features/**/*_spec.rb"
  end

  # disable noisy backtraces:
  config.filter_rails_from_backtrace!
  config.filter_gems_from_backtrace("capybara")
  config.filter_gems_from_backtrace("omniauth")
  config.filter_gems_from_backtrace("railties")
  config.filter_gems_from_backtrace("puma")
  config.filter_gems_from_backtrace("rack")
  config.filter_gems_from_backtrace("request_store")
  config.filter_gems_from_backtrace("sentry-raven")
  config.filter_gems_from_backtrace("warden")
end

require "cdx"
require "pry-byebug"
