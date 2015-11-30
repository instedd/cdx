require 'active_support/concern'
require 'active_support/core_ext/module/aliasing'

# inspired in https://gist.github.com/phillbaker/7617703
module DefaultParamsHelper
  extend ActiveSupport::Concern

  def process_with_default_params(action, *args)
    if args[1].nil? || args[1].is_a?(Hash)
      args[1] = default_params.merge(args[1] || {})
    end
    process_without_default_params(action, *args)
  end

  included do
    let(:default_params) { {} }
    alias_method_chain :process, :default_params
  end
end
