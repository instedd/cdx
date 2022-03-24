require 'active_support/concern'
require 'active_support/core_ext/module/aliasing'

module DefaultParamsHelper
  extend ActiveSupport::Concern

  included do
    let(:default_params) { {} }
  end

  if Rails::VERSION::MAJOR >= 5
    def process(action, params: {}, **kwargs)
      super action, params: add_defaults_to(params), **kwargs
    end
  else
    # NOTE: backport of new DSL in Rails 5

    %w[head get post put patch delete].each do |name|
      define_method name do |action, **kwargs|
        process action, method: name.upcase, **kwargs
      end
    end

    def process(action, method: "GET", params: {}, session: nil, body: nil, flash: {}, format: nil, xhr: false, as: nil)
      if xhr
        @request.set_header "HTTP_X_REQUESTED_WITH", "XMLHttpRequest"
        @request.fetch_header("HTTP_ACCEPT") do |k|
          @request.set_header k, [Mime[:js], Mime[:html], Mime[:xml], "text/xml", "*/*"].join(", ")
        end
      end

      if as
        @request.content_type = Mime[as].to_s
        format ||= as
      end

      params = add_defaults_to(params)
      params[:format] = format unless format.nil?

      if body
        super action, method, body, params, session, flash
      else
        super action, method, params, session, flash
      end
    end
  end

  private

  def add_defaults_to(params)
    if params.nil?
      default_params.dup
    elsif params.is_a?(Hash)
      default_params.merge(params)
    end
  end
end
