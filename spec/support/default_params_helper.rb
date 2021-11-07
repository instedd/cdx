require 'active_support/concern'
require 'active_support/core_ext/module/aliasing'

# inspired in https://gist.github.com/phillbaker/7617703
module DefaultParamsHelper
  extend ActiveSupport::Concern

  def process_with_default_params(action, *args)

    puts "HEEEEEEEY"
    puts action
    puts args[0]
    puts args[1]
    puts "END"

    # if args[1].nil? || args[1].is_a?(Hash)
    #   args[1] = default_params.merge(args[1] || {})
    # end

    # Fix
    # DEPRECATION WARNING: Using positional arguments in functional tests has been deprecated,
    # in favor of keyword arguments, and will be removed in Rails 5.1.
    params = args[0][:params]
    if params.nil? || params.is_a?(Hash)
      params = default_params.merge(params || {})
    end
    args[0][:params] = params

    puts "HEEEEEEEY"
    puts args[0]
    puts args[1]

    process_without_default_params(action, *args)
  end

  included do
    let(:default_params) { {} }
    alias_method_chain :process, :default_params
  end
end
