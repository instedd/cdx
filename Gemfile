source 'https://rubygems.org'

# gem 'rails', '~> 4.2.5'
gem 'rails', '~> 5.0.7'
gem 'mysql2'
gem 'sass-rails', '~> 5.0.0'
gem 'uglifier', '>= 2.7.2'
gem 'jquery-rails', '~> 4.4.0'
gem 'haml-rails', '~> 1.0.0'
gem 'lodash-rails', '~> 4.17.15'
gem 'awesome_nested_set', '~> 3.4.0' #'~> 3.1.0' #'~> 3.0.0.rc.3'
gem 'csv_builder', '~> 2.1.3'
gem 'decent_exposure', '~> 3.0.4'
gem 'nokogiri', '~> 1.11.3' #'~> 1.6.8.1'
gem 'react-rails', '~> 2.6.1' #'~> 1.3.2'
gem 'foreman', '~> 0.87.2'
gem 'paperclip', git: 'https://github.com/instedd/paperclip', branch: 'fix/v4.3.6-no-mimemagic'
gem 'aws-sdk-s3', '~> 1.93.1' #'~> 3.0.2' #'~> 1.6'
gem 'newrelic_rpm', '~> 6.15.0'
gem 'paranoia', '~> 2.4.3' #'~> 2.2.0'
gem 'premailer-rails', '~> 1.11.1'
gem 'kaminari', '~> 1.2.1'
gem 'base58', '~> 0.2.3'
gem 'rubyzip', '~> 2.3.0' #'>= 1.0.0'

gem 'poirot_rails', git: 'https://github.com/instedd/poirot_rails.git', branch: 'master'
gem 'config', '~> 3.1.0'
gem 'rest-client', '~> 1.6' #'~> 2.1.0' TODO: update location_service
gem 'barby', '~> 0.6.8'
gem 'chunky_png', '~> 1.4.0'
gem 'wicked_pdf', '~> 2.1'
gem 'gon', '~> 6.4.0'
gem 'rchardet', '~> 1.8.0'
gem 'therubyracer', '~> 0.12.3'
gem 'd3_rails', '~> 4.1.1'

gem 'cdx', path: '.'
gem 'cdx-api-elasticsearch', path: '.'
gem 'cdx-sync-server', git: 'https://github.com/instedd/cdx-sync-server.git', branch: 'master'
gem 'geojson_import', git: 'https://github.com/instedd/geojson_import', branch: 'master'
gem 'location_service', git: 'https://github.com/instedd/ruby-location_service.git', branch: 'master'
gem 'view_components', git: 'https://github.com/manastech/rails-view_components.git', branch: 'master'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.2.1'
gem 'jquery-turbolinks', '~> 2.1.0'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.9.1' #'~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'

gem 'puma', '~> 5.2.2'

# Use Sidekiq for background jobs
gem 'sidekiq', '~> 5.1.3'
# gem 'sinatra', '~> 1.4.8'
gem 'sidekiq-cron', '~> 1.2.0' #'~> 0.3.1'

group :development do
  gem 'letter_opener', '~> 1.7.0'
  gem 'web-console', '~> 2.0'
  gem 'capistrano', '~> 3.1.0', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1', require: false
  gem 'capistrano-rvm', '~> 0.1', require: false
  gem 'spring'
  gem 'spring-commands-rspec'
  # gem 'quiet_assets'
end

gem 'devise', '~> 4.7.3' #'~> 3.5.5'
gem 'devise_security_extension', git: 'https://github.com/phatworx/devise_security_extension', tag: 'v0.7.2'
gem 'devise_invitable', '~> 2.0.4'
gem 'omniauth', '~> 2.0.4'
gem 'omniauth-google-oauth2', '~> 1.0.0'
gem 'elasticsearch'

gem 'oj', '~> 3.11.3'
gem 'guid'
gem 'encryptor'

gem 'dotiw'
gem 'rails-i18n', '~> 5.0.0' #'~> 4.0.9' # '5.1.1' #'~> 4.0.0'
gem 'doorkeeper'

gem 'faker'
gem 'leaflet-rails'

gem 'nuntium_api', '~> 0.21'

source 'https://rails-assets.org' do
  gem 'rails-assets-urijs'
end

group :development, :test do
  gem 'pry-byebug', '~> 3.9.0'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'pry-clipboard'
  gem 'rspec-rails', '~> 4.1.2'
end

group :test do
  gem 'testrail_rspec_formatter'
  gem 'test-unit'
  gem 'tire'
  # gem 'factory_girl_rails'
  gem 'machinist', '~> 1.0'
  gem 'capybara', '~> 3.35.3'
  gem 'guard-rspec'
  gem 'rspec', '~> 3.10.0'
  gem 'rspec-collection_matchers'
  gem 'vcr'
  gem 'webmock', require: false
  gem 'capybara-mechanize', '~> 1.11.0'
  gem 'timecop'
  gem 'shoulda'
  gem 'hashdiff'
  gem 'cucumber-rails', '~> 2.0.0', :require => false
  gem 'database_cleaner'
  gem 'site_prism', '~> 3.7.1'
  gem 'poltergeist', '~> 1.18.1'
  gem 'capybara-screenshot', '~> 1.0.25'

  source 'https://rails-assets.org' do
    gem 'rails-assets-es5-shim'
  end
end
