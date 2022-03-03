RSpec.configure do |config|
  config.before(:suite) do
    # Cleanup the database on startup, in case tables haven't been properly
    # cleaned up during a previous run.
    #
    # We delete instead of truncating the table, since there shouldn't be any
    # (or much) rows to delete in the table, compared to truncation that will
    # destroy and recreate each table from scratch, inducing a longer startup,
    # which negatively impacts repeated runs when focusing specs.
    DatabaseCleaner.clean_with :deletion, pre_count: true
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  # Configure DatabaseCleaner to use deletion strategy with JavaScript specs.
  #
  # We want to ensure we're not using transactions as the work they do is
  # isolated to one database connection. One database connection is used by
  # the specs, and another, separate database connection is
  # used by the app server phantomjs interacts with. Truncation, when *not*
  # inside a transaction, affects all database connections, so truncation is
  # what we need!
  # http://www.railsonmaui.com/tips/rails/capybara-phantomjs-poltergeist-rspec-rails-tips.html
  # http://devblog.avdi.org/2012/08/31/configuring-database_cleaner-with-rails-rspec-capybara-and-selenium/
  #
  # We choose deletion instead of truncation for the same reasons than explained
  # above (in the before :suite cleanup), but with a higher impact since it
  # happens before :each spec, instead of once on startup!
  config.before(:each, js: true) do
    DatabaseCleaner.strategy = [:deletion, { pre_count: true }]
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end
end
