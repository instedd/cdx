# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/collection_matchers'
require 'coffee_script'

require 'capybara/rspec'
# require 'capybara/mechanize'
require 'capybara/poltergeist'
require 'webmock/rspec'
require 'capybara-screenshot/rspec'

Capybara.javascript_driver = :poltergeist


# HTTPI.log = false
# Savon.log = false

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("features/support/page_objects/*.rb")].each {|f| require f}
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

WebMock.disable_net_connect!(:allow_localhost => true, allow: [/fonts\.googleapis\.com/, /manastech\.testrail\.com/, /elasticsearch/])

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
  config.include ManifestSpecHelper
  config.include CdxFieldsHelper
  config.include FeatureSpecHelpers, :type => :feature

  config.before(:each) do
    stub_request(:get, "http://fonts.googleapis.com/css").
         with(:query => hash_including(:family)).
         to_return(:status => 200, :body => "", :headers => {})
  end

  config.before(:each) do
    LocationService.fake!
    Timecop.return
    ActionMailer::Base.deliveries.clear
  end

  config.after(:each) do
    Timecop.return
  end

  config.exclude_pattern = "spec/features/**/*_spec.rb"
end

require "bundler/setup"
require "cdx"
require "pry-byebug"
