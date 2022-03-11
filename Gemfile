source 'https://rubygems.org'

gem 'rails', '~> 4.2.11'
gem 'rake', '~> 10.5.0'

# Databases
gem 'mysql2', '~> 0.3'
gem 'elasticsearch', '~> 1.0'

# Models
gem 'encryptor', '~> 1.3'
gem 'kaminari', '~> 0.16'
gem 'paperclip', git: 'https://github.com/instedd/paperclip', branch: 'fix/v4.3.6-no-mimemagic'
gem 'paranoia', '<= 2.4.2' # last version to support ruby 2.2
gem 'premailer-rails', '~> 1.8'

# Views
gem 'csv_builder', '~> 2.1'
gem 'haml-rails', '~> 0.9'
gem 'jbuilder', '~> 1.2'
gem 'view_components', git: 'https://github.com/manastech/rails-view_components.git', branch: 'master'
gem 'wicked_pdf', '~> 2.1'

# Authentication
# gem 'bcrypt-ruby', '~> 3.1.2'
gem 'devise', '~> 3.5.5'
gem 'devise-security', '<= 0.12.0' # last version to support ruby 2.2
#gem 'devise_security_extension', git: 'https://github.com/phatworx/devise_security_extension'
gem 'devise_invitable', '~> 1.5'
gem 'doorkeeper', '~> 3.0'
gem 'omniauth', '~> 1.2'
gem 'omniauth-google-oauth2', '~> 0.2'

# Libraries
gem 'aws-sdk', '~> 1.6'
gem 'base58', '~> 0.1'
gem 'barby', '~> 0.6'
gem 'config', '~> 1.2'
gem 'dotiw', '~> 3.0'
gem 'faker' # NOTE: until we upgrade to ruby 2.5+ then we can upgrade to ffaker 2.20 to replace Faker::Number
gem 'ffaker'
gem 'guid', '~> 0.1'
gem 'nokogiri', '~> 1.6'
gem 'oj', '~> 2.12'
gem 'poirot_rails', git: 'https://github.com/instedd/poirot_rails.git', branch: 'master'
gem 'rails-i18n', '~> 4.0'
gem 'rchardet', '~> 1.6'
gem 'rest-client', '~> 1.8' # NOTE: only used for a single HTTP call
gem 'rubyzip', '>= 1.0.0'
gem 'rqrcode', '~> 0.10' # required by Barby::QRCode

gem 'cdx', path: '.'
gem 'cdx-api-elasticsearch', path: '.'
gem 'cdx-sync-server', git: 'https://github.com/instedd/cdx-sync-server.git', branch: 'master'
gem 'geojson_import', git: 'https://github.com/instedd/geojson_import', branch: 'master'

# group :doc do
#   # bundle exec rake doc:rails generates the API under doc/api.
#   gem 'sdoc', require: false
# end

# Services
gem 'puma', '~> 2.13'
gem 'sidekiq', '~> 3.5'
gem 'sinatra', '~> 1.4' # for sidekiq web
gem 'sidekiq-cron', '~> 0.3'
gem 'whenever', '~> 1.0' # TODO: replace with a sidekiq-cron job

# External services
gem 'location_service', git: 'https://github.com/instedd/ruby-location_service.git', branch: 'master'
gem 'nuntium_api', '~> 0.21'
gem 'sentry-raven', '~> 2.13'

# Assets
gem 'gon', '~> 6.0'
gem 'therubyracer', '~> 0.12'
gem 'sass-rails', '~> 4.0'
gem 'turbolinks', '~> 2.5'
gem 'uglifier', '>= 2.7.2'

gem 'd3_rails', '~> 3.5'
gem 'dropzonejs-rails', '~> 0.8'
gem 'jquery-rails', '~> 4.0'
gem 'jquery-turbolinks', '~> 2.1'
gem 'leaflet-rails', '~> 0.7'
gem 'lodash-rails', '~> 3.10'
gem 'react-rails', '~> 1.3'

source 'https://rails-assets.org' do
  gem 'rails-assets-urijs', '~> 1.17'
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
  gem 'rspec', '~> 3.3'
  gem 'rspec-collection_matchers', '~> 1.1'
  gem 'rspec-rails', '~> 3.3'

  gem 'database_cleaner', '~> 1.99'
  gem 'machinist', '~> 2.0' # NOTE: eventually replace with FactoryBot
  gem 'simplecov', require: false
  gem 'timecop', '~> 0.8'
  gem 'webmock', '~> 1.12', require: false

  # integration tests
  gem 'capybara', '~> 2.4'
  gem 'capybara-screenshot', '~> 1.0'
  gem 'cucumber-rails', '~> 1.5', require: false
  gem 'selenium-webdriver', '< 4.0'
  gem 'site_prism', '~> 2.17'
end
