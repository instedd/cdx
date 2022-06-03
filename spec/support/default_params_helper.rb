require 'active_support/concern'
require 'active_support/core_ext/module/aliasing'

module DefaultParamsHelper
  extend ActiveSupport::Concern

  included do
    let(:default_params) { {} }
  end

  def process(action, params: {}, **kwargs)
    super action, params: add_defaults_to(params), **kwargs
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
