source 'https://rubygems.org'

gem 'rails', '~> 4.2.5'

# Databases
gem 'mysql2'
gem 'elasticsearch'

# Models
gem 'encryptor'
gem 'kaminari'
gem 'paperclip', git: 'https://github.com/instedd/paperclip', branch: 'fix/v4.3.6-no-mimemagic'
gem 'paranoia'
gem 'premailer-rails'

# Views
gem 'csv_builder'
gem 'haml-rails'
gem 'jbuilder', '~> 1.2'
gem 'view_components', git: 'https://github.com/manastech/rails-view_components.git', branch: 'master'
gem 'wicked_pdf', '~> 2.1'

# Authentication
# gem 'bcrypt-ruby', '~> 3.1.2'
gem 'devise', '~> 3.5.5'
gem 'devise_security_extension', git: 'https://github.com/phatworx/devise_security_extension'
gem 'devise_invitable'
gem 'doorkeeper'
gem 'omniauth'
gem 'omniauth-google-oauth2'

# Libraries
gem 'aws-sdk', '~> 1.6'
gem 'base58'
gem 'barby'
gem 'config', '~> 1.2.0'
gem 'dotiw'
gem 'faker' # NOTE: until we upgrade to ruby 2.5+ then we can upgrade to ffaker 2.20 to replace Faker::Number
gem 'ffaker'
gem 'guid'
gem 'nokogiri', '~> 1.6.7.2'
gem 'oj'
gem 'poirot_rails', git: 'https://github.com/instedd/poirot_rails.git', branch: 'master'
gem 'rails-i18n', '~> 4.0.0'
gem 'rchardet'
gem 'rest-client' # NOTE: only used for a single HTTP call
gem 'rubyzip', '>= 1.0.0'
gem 'rqrcode', '~> 0.10.1' # required by Barby::QRCode

gem 'cdx', path: '.'
gem 'cdx-api-elasticsearch', path: '.'
gem 'cdx-sync-server', git: 'https://github.com/instedd/cdx-sync-server.git', branch: 'master'
gem 'geojson_import', git: 'https://github.com/instedd/geojson_import', branch: 'master'

# group :doc do
#   # bundle exec rake doc:rails generates the API under doc/api.
#   gem 'sdoc', require: false
# end

# Services
gem 'puma'
gem 'sidekiq'
gem 'sinatra' # for sidekiq web
gem 'sidekiq-cron', '~> 0.3.1'
gem 'whenever', '~> 1.0' # TODO: replace with a sidekiq-cron job

# External services
gem 'location_service', git: 'https://github.com/instedd/ruby-location_service.git', branch: 'master'
gem 'nuntium_api', '~> 0.21'
gem 'sentry-raven'

# Assets
gem 'd3_rails'
gem 'dropzonejs-rails', '0.8.4'
gem 'gon'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'leaflet-rails'
gem 'lodash-rails'
gem 'react-rails', '~> 1.3.2'
gem 'sass-rails', '~> 4.0.0'
gem 'therubyracer'
gem 'turbolinks'
gem 'uglifier', '>= 2.7.2'

source 'https://rails-assets.org' do
  gem 'rails-assets-urijs'

  group :test do
    gem 'rails-assets-es5-shim'
  end
end

group :development do
  gem 'letter_opener'
  gem 'quiet_assets'
  gem 'web-console', '~> 2.0'
end

group :development, :test do
  gem 'pry-byebug'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'pry-clipboard'
  gem 'spring'
  gem 'spring-commands-rspec'
end

group :test do
  gem 'rspec'
  gem 'rspec-collection_matchers'
  gem 'rspec-rails'

  gem 'database_cleaner'
  gem 'machinist', '~> 2.0' # NOTE: eventually replace with FactoryBot
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'webmock', require: false

  # integration tests
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'cucumber-rails', require: false
  gem 'poltergeist'
  gem 'site_prism'
end
