class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Policy::Actions

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_filter :verify_authenticity_token, if: :json_request?

  before_action :authenticate_user!
  before_action :check_no_institution!
  before_action :load_current_user_policies
  before_action :load_js_global_settings

  before_action do
    @main_column_width = if params[:action] != 'index'
      8
    else
      10
    end
  end

  decent_configuration do
    strategy DecentExposure::StrongParametersStrategy
  end

  def render_json(object, params={})
    render params.merge(text: object.to_json_oj, content_type: 'text/json')
  end

  def self.set_institution_tab(key)
    before_filter do
      send :set_institution_tab, key
    end
  end

  def set_institution_tab(key)
    @institution_tab = key
  end

  def load_current_user_policies
    if current_user
      @current_user_policies = current_user.policies.load
    end
  end

  def load_js_global_settings
    gon.location_service_url = Settings.location_service_url
    gon.location_service_set = Settings.location_service_set
  end

  def authorize_resource(resource, action)
    if Policy.can?(action, resource, current_user, @current_user_policies)
      Policy.authorize(action, resource, current_user, @current_user_policies)
    else
      head :forbidden
      nil
    end
  end

  def authorize_test_result(test_result)
    head :forbidden unless [test_result.institution, test_result.laboratory, test_result.device].any? {
      |resource| Policy.can?(QUERY_TEST, resource, current_user, @current_user_policies)
    }
  end

  def check_no_institution!
    if current_user && current_user.institutions.empty?
      redirect_to new_institution_path
    end
  end

  protected

  def json_request?
    request.format.json?
  end
end
