RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  # Configure DatabaseCleaner to use truncation strategy with
  # JavaScript (js: true) specs.
  #
  # We want to ensure we're not using transactions as the work they do is
  # isolated to one database connection. One database connection is used by
  # the specs, and another, separate database connection is
  # used by the app server phantomjs interacts with. Truncation, when *not*
  # inside a transaction, affects all database connections, so truncation is
  # what we need!
  # http://www.railsonmaui.com/tips/rails/capybara-phantomjs-poltergeist-rspec-rails-tips.html
  # http://devblog.avdi.org/2012/08/31/configuring-database_cleaner-with-rails-rspec-capybara-and-selenium/
  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
