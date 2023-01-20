require_relative 'boot'
require_relative '../lib/ruby_dig' # TODO: remove after upgrading to RUBY 2.3

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Cdp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.react.addons = true

    config.generators do |g|
      g.test_framework :rspec
      g.assets = false
    end
    config.autoload_paths << Rails.root.join("features", "support", "page_objects")
    config.autoload_paths += %W(#{config.root}/documents #{config.root}/lib)

    config.assets.precompile += %w( mailer.css )

    config.action_mailer.asset_host = "http://#{Settings.host}"

    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    # disable <div class="field_with_errors"> wrapper
    config.action_view.field_error_proc = Proc.new { |html_tag, instance| html_tag }
  end

  def self.version
    if File.exist?(Rails.root.join("VERSION"))
      File.read(Rails.root.join("VERSION")).strip
    else
      "development"
    end
  end
end
