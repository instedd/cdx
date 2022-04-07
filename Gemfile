def next?(next_version = nil, current_version = nil)
  is_next = File.basename(__FILE__) == "Gemfile.next"

  if next_version && current_version
    is_next ? next_version : current_version
  else
    is_next
  end
end

source 'https://rubygems.org'

gem 'rails', next?('~> 5.0.0', '~> 4.2.11')

gem 'globalid', '< 0.5.0'        # NOTE: remove gem after upgrading to ruby 2.5
gem 'rack', '< 2.2.0' if next?   # NOTE: remove gem after upgrading to ruby 2.3
gem 'rake', '~> 10.5.0'          # NOTE: remove gem after upgrading rspec
gem 'sprockets-rails', '< 3.3.0' # NOTE: remove gem after upgrading to ruby 2.5

# Databases
gem 'mysql2', '~> 0.3'
gem 'elasticsearch', '~> 1.0'

# Models
gem 'encryptor', '~> 1.3'
gem 'kaminari', '~> 0.16'
gem 'paperclip', git: 'https://github.com/instedd/paperclip', branch: 'fix/v4.3.6-no-mimemagic'
gem 'paranoia', '<= 2.4.2' # last version to support ruby 2.2
gem 'premailer-rails', '< 1.10' # 1.10 requires Rails.application.assets_manifest

# Views
gem 'csv_builder', '~> 2.1'
gem 'haml-rails', '~> 0.9'
gem 'jbuilder', '~> 2.5'
gem 'view_components', git: 'https://github.com/manastech/rails-view_components.git', branch: 'master'
gem 'wicked_pdf', '~> 2.1'

# Authentication
# gem 'bcrypt-ruby', '~> 3.1.2'
gem 'devise', '~> 4.0.0'
gem 'devise-security', '<= 0.12.0' # last version to support ruby 2.2
gem 'devise_invitable', '~> 1.5'
gem 'doorkeeper', '~> 5.0.3'
gem 'omniauth', '~> 1.2'
gem 'omniauth-google-oauth2', '~> 0.2'

# Libraries
gem 'aws-sdk', '~> 1.6'
gem 'base58', '~> 0.1'
gem 'barby', '~> 0.6'
gem 'config', '~> 1.2'
gem 'dotiw', '~> 3.0'
gem 'faker', '< 1.9.2' # NOTE: kept until we upgrade to ruby 2.5+ then we can upgrade to ffaker 2.20 to replace Faker::Number
gem 'ffaker', '< 2.12.0'
gem 'guid', '~> 0.1'
gem 'nokogiri', '~> 1.6', '< 1.10.0' # last version to support ruby 2.2
gem 'oj', '~> 2.12', '< 2.17.3' # NOTE: 2.17.3 will stringify Time as a Float then load a BigDecimal...
gem 'poirot_rails', git: 'https://github.com/instedd/poirot_rails.git', branch: 'master'
gem 'rails-i18n', next?('~> 5.0', '~> 4.0')
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
gem 'puma', next?('~> 3.0', '~> 2.13')
gem 'sidekiq', '~> 4.2'
gem 'sidekiq-cron', '~> 0.3' # TODO: not maintained, consider sidekiq-scheduler instead
gem 'whenever', '~> 1.0' # TODO: replace with a sidekiq-cron job

# External services
gem 'location_service', git: 'https://github.com/instedd/ruby-location_service.git', branch: 'master'
gem 'nuntium_api', '~> 0.21'
gem 'sentry-raven', '~> 2.13'

# Assets
gem 'execjs', '< 2.8.0' # 2.8 removed support for therubyracer
gem 'gon', '~> 6.0'
if next?
  gem 'sass-rails', '~> 5.0', '< 5.0.8'
else
  gem 'sass-rails', '~> 4.0'
end
gem 'therubyracer', '~> 0.12' # FIXME: deprecated for years
gem 'turbolinks', '~> 2.5' # TODO: next?('~> 5', '~> 2.5')
gem 'uglifier', '~> 2.7'

# TODO: externalize frontend dependencies (NPM or YARN)!
gem 'd3_rails', '~> 3.5.6'
gem 'dropzonejs-rails', '~> 0.8.4'
gem 'jquery-rails', '~> 4.0'
gem 'jquery-turbolinks', '~> 2.1.0'
gem 'leaflet-rails', '~> 0.7.4'
gem 'lodash-rails', '~> 3.10.1'
gem 'react-rails', '~> 1.3.2'

source 'https://rails-assets.org' do
  gem 'rails-assets-urijs', '~> 1.17.0'
end

group :development do
  gem 'letter_opener'
  gem 'listen', '~> 3.0.5' if next?
  gem 'quiet_assets' unless next?
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '~> 2.0.0' if next?
  gem 'web-console', '< 4.0' # last version to support ruby 2.2
end

group :development, :test do
  gem 'pry-byebug', '< 2.7.0' # last version to support ruby 2.2
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
end

group :test do
  gem 'rspec', '~> 3.3'
  gem 'rspec-collection_matchers', '~> 1.1'
  gem 'rspec-rails', '~> 3.3'

  gem 'database_cleaner', '~> 1.99'
  gem 'machinist', '~> 2.0' # NOTE: eventually replace with FactoryBot
  gem 'rails-controller-testing' if next?
  gem 'simplecov', require: false
  gem 'timecop', '~> 0.8'
  gem 'webmock', '~> 1.23.0', require: false # a spec fails with 1.24.x

  # integration tests
  gem 'capybara', '~> 2.4'
  gem 'capybara-screenshot', '~> 1.0'
  gem 'cucumber-rails', '~> 1.5', require: false
  gem 'selenium-webdriver', '< 4.0'
  gem 'site_prism', '~> 2.17'
end
