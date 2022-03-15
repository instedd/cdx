require 'active_support/concern'
require 'active_support/core_ext/module/aliasing'

module DefaultParamsHelper
  extend ActiveSupport::Concern

  # TODO: leverage kwargs once we're fully migrated to Rails 5!
  def process(action, *args)
    if Rails::VERSION::MAJOR >= 5 && kwarg_request?(args)
      kwargs = args[0]
      kwargs[:params] = add_defaults_to(kwargs[:params])
      return super(action, **kwargs)
    end

    if args[1].nil? || args[1].is_a?(Hash)
      args[1] = default_params.merge(args[1] || {})
    end

    if Rails::VERSION::MAJOR >= 5
      http_method = args.shift

      if args[0].is_a?(String) && http_method != 'HEAD'
        body = args.shift
      end
      params, session, flash = args

      # if params || session || flash
      #   non_kwarg_request_warning
      # end

      super action, method: http_method, params: params, body: body, session: session, flash: flash
    else
      super action, *args
    end
  end

  if Rails::VERSION::MAJOR >= 5
    @@non_kwarg_request_warning_counter = 0

    def non_kwarg_request_warning
      if (@@non_kwarg_request_warning_counter += 1) == 1
        super
      else
        # don't repeat warning
      end
    end
  end

  included do
    let(:default_params) { {} }
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
