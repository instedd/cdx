# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

# Allow components and view helpers to be used in assets
# source: https://github.com/sstephenson/sprockets/issues/218#issuecomment-94729397
module HTMLAssets
  class LookupContext < ActionView::LookupContext
    def initialize(context, path)
      super(path)
      @view_context = context
    end

    def find_template(*args)
      super.tap do |r|
        @view_context.depend_on(r.identifier)
      end
    end
  end

  module ViewContext
    include ApplicationHelper

    def to_jsx(str)
      str.gsub("class=", "className=")
    end

    attr_accessor :output_buffer

    def view_renderer
      @_view_renderer ||= ActionView::Renderer.new(lookup_context)
    end

    def lookup_context
      @_lookup_context ||= LookupContext.new(self, environment.paths.to_a + [File.join(Rails.root, "app", "views")])
    end

    def output_buffer_with_sprockets=(buffer)
      unless is_sprockets?
        output_buffer_without_sprockets=(buffer)
      end
    end

    def is_sprockets?
      self.try(:environment).class == Sprockets::Index
    end

    def self.included(klass)
      klass.instance_eval do
        include Rails.application.routes.url_helpers
        include Rails.application.routes.mounted_helpers
        include ActionView::Helpers
        alias_method_chain :output_buffer=, :sprockets
      end
    end
  end
end

Rails.application.assets.context_class.class_eval do
  include HTMLAssets::ViewContext
end

Rails.application.config.assets.precompile += ['active_admin.js', 'active_admin.css', 'active_admin/print.css']

