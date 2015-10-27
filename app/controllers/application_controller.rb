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
      6
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

  def check_no_institution!
    return if current_user && current_user.need_change_password?
    if current_user && current_user.institutions.empty? && current_user.policies.empty?
      if has_access?(Institution, CREATE_INSTITUTION)
        redirect_to new_institution_path
      else
        @hide_nav_bar = true
      end
    end
  end

  # filters/authorize @institutions by action. Assign calls resource.institution= if only one institution was left
  def prepare_for_institution_and_authorize(resource, action)
    @institutions = authorize_resource(@institutions, action)
    if @institutions.blank?
      head :forbidden
      nil
    elsif @institutions.one?
      resource.institution = @institutions.first
      @institutions
    else
      @institutions
    end
  end

  protected

  def json_request?
    request.format.json?
  end
end
